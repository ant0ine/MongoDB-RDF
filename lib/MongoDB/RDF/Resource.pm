package MongoDB::RDF::Resource;
use strict;
use warnings;

use JSON::Any;
use MongoDB::OID;

use MongoDB::RDF::Namespace qw( resolve );
use MongoDB::RDF::Util qw( canonical_uri looks_like_uri fencode fdecode );

my %Rdf_type2class;
my %Class2rdf_type;

=head1 NAME

MongoDB::RDF::Resource

=head1 SYNOPSIS

 use MongoDB::RDF::Resource;

 my $r =  MongoDB::RDF::Resource->new('http://foo.bar');
 $r->dc_title('My title');

=head1 DESCRIPTION

=head1 METHODS

=head2 $class->new( $uri )

if $uri is undef, then a blank node is created.

=cut

sub new {
    my $class = shift;
    my ($subject) = @_;

    my $self = bless {
        document => {},
    }, $class;

    $self->set_subject($subject);

    if (my $type = $Class2rdf_type{$class}) {
        $self->set(rdf_type => $type);    
    }

    $self->init if $self->can('init');

    return $self;
}

=head2 $self->set_subject( $uri )

Set the subject, if $uri is undef a blank node URI is created.
(Used by the constructor)

=cut

sub set_subject {
    my $self = shift;    
    my ($uri) = @_;
    unless ($uri) {
        my $oid = MongoDB::OID->new;
        $self->{document}{_id} = $oid;
        $uri = 'urn:oid:'.$oid->value;
    }
    return $self->{document}{_subject} = canonical_uri($uri);
}

=head2 $self->subject

Returns the subject.

=cut

sub subject {
    my $self = shift;    
    return $self->{document}{_subject};
}

=head2 $self->uri

Alias of subject

=cut

sub uri { shift->subject }


sub _rdf_type_to_class { $Rdf_type2class{$_[1]} }

sub _class_to_rdf_type { $Class2rdf_type{$_[1]} }

sub _new_from_document {
    my $class = shift;
    my ($doc) = @_;
    return unless $doc;
    my $self = bless { document => $doc }, 'MongoDB::RDF::Resource';
    if (my $type = $self->get('rdf_type')) {
        if (my $subclass = $Rdf_type2class{$type}) {
            bless $self, $subclass;
        }
    }
    return $self;
}

=head2 properties

=cut

# TODO make decoded option the default ?

sub properties {
    my $self = shift;
    my %opts = @_;
    my %p;
    for my $key ( keys %{ $self->document }) {
        next if $key eq '_id';
        next if $key eq '_subject';
        my $value = $self->document->{$key};
        $key = fdecode($key) if $opts{decoded};
        $p{$key} = $value;
    }
    return \%p;
}

sub _property {
    my $self = shift;    
    my ($uri, $values) = @_;
    if ($values) {
        die 'must be an arrayref' unless ref $values eq 'ARRAY';    
        $self->{document}{$uri} = $values;
    }
    return $self->{document}{$uri};
}

# object in the "subject predicate object" sense
sub _value2object {
    my $self = shift;    
    my ($value) = @_;
    if (looks_like_uri($value)) {
        return { type => 'uri', value => canonical_uri($value) };
    }
    else {
        return { type => 'literal', value => $value };
    }
}

sub _object2value {
    my $self = shift;    
    my ($object, $opts) = @_;
    if (my $graph = $opts->{instanciate}) {
        die '['.$self->mongodb_id.'] type is not uri, value: '.$object->{value}
            unless $object->{type} eq 'uri';
        return $graph->load($object->{value});
    }
    else {
        return $object->{value};
    }
}

=head1 PROPERTY METHODS

$predicate can be a canonical URI string, or the namespace notation.
Also this namespace notation can be used directly as a method to replace 'get' and 'set'.

Example:

 $self->get( 'http://purl.org/dc/elements/1.1/title' );
 # or
 $self->get( 'dc_title' );
 # or
 $self->dc_title;

=head2 $self->get( $predicate )

=cut

sub get {
    my $self = shift;    
    my ($predicate) = @_;
    my $uri = fencode(resolve($predicate));
    my @values = map {
        $self->_object2value($_)
    } @{ $self->_property($uri) || [] };
    return wantarray ? @values : shift @values;
}

=head2 $self->add( $predicate => $value )

=cut

sub add {
    my $self = shift;    
    my ($predicate, $value) = @_;
    my $uri = fencode(resolve($predicate));
    my $props = $self->_property($uri);
    push @$props, $self->_value2object($value);
    $self->_property($uri, $props);
    return 1;
}

=head2 $self->del( $predicate => $value )

=cut

sub del {
    my $self = shift;    
    my ($predicate, $value) = @_;
    my $uri = fencode(resolve($predicate));
    my $props = $self->_property($uri);
    my $obj = $self->_value2object($value);
    my @new = grep {
        $_->{value} ne $obj->{value}
    } @$props;
    $self->_property($uri, \@new);
    return 1;
}

=head2 $self->set( $predicate => [ $v1, $v2, ...] )

=cut

sub set {
    my $self = shift;    
    my $predicate = shift;
    my $values = \@_;
    my $uri = fencode(resolve($predicate));
    my @objs = map { $self->_value2object($_) } @$values;
    $self->_property($uri, \@objs);
    return 1;
}

=head1 GRAPH METHODS

=head2 $self->get_resources( $predicate , $graph )

=cut

sub get_resources {
    my $self = shift;
    my ($predicate, $graph) = @_;
    my $uri = fencode(resolve($predicate));
    my @values = map {
        $self->_object2value($_, { instanciate => $graph })
    } @{ $self->_property($uri) || [] };
    return wantarray ? @values : shift @values;
}

=head2 $self->get_referer_resources( $predicate, $graph )

=cut

sub get_referer_resources {
    my $self = shift;
    my ($predicate, $graph) = @_;
    my $cursor = $graph->find({ $predicate => $self->subject });
    my @refs;
    while (my $ref = $cursor->next) { push @refs, $ref; }
    return wantarray ? @refs : shift @refs;
}

=head1 EXPORT METHODS

=head2 $self->as_rdf_json

Returns a RDF/JSON document. See <http://n2.talis.com/wiki/RDF_JSON_Specification>.

=cut

sub as_rdf_json {
    my $self = shift;    
    my $obj = {
        $self->subject => $self->properties( decoded => 1 )
    };
    my $j = JSON::Any->new; 
    return $j->objToJson($obj);
}

=head2 $self->as_rdf_xml

=cut

sub as_rdf_xml {
    my $self = shift;    
    # TODO 
}

=head2 $self->as_ntriples

Loads the NTriples serializer and return the resource serialized in NTriples.

=cut

sub as_ntriples {
    my $self = shift;
    my $class = 'MongoDB::RDF::Serializer::NTriples';
    eval "require $class";
    return $class->serialize_resource($self);
}

=head1 ACCESSING UNDERLYING MONGODB OBJECTS

=head2 $self->mongodb_id

Returns the MongoDB ID of the document.

=cut

sub mongodb_id {
    my $oid = $_[0]->document->{_id};
    return $oid ? $oid->value : undef;
}

=head2 $self->document

Returns the document as stored in MongoDB.

=cut

sub document { $_[0]->{document} }

=head1 SUBSCLASSING

MongoDB::RDF::Resource can be subsclassed like this:

 package MyClass;
 use base qw( MongoDB::RDF::Resource );

 __PACKAGE__->register_rdf_type( 'http://my.domain/myclass' );

 ...

 my $r = MyClass->new('http://myinstance');
 # $r->rdf_type is 'http://my.domain/myclass'
 $graph->save($r);

 ...
 
 my $r = $graph->load('http://myinstance');
 # $r is a MyClass

Your class is now associated with a rdf_type. When this class will be instanciated,
the objects will automatically get the corresponding rdf_type property.
The same when this resource will be loaded from the graph,
it will be blessed into the corresponding class.

=head2 $class->register_rdf_type( $uri )

=cut

sub register_rdf_type {
    my $class = shift;
    my ($uri) = @_;
    $uri = canonical_uri($uri);
    $Rdf_type2class{$uri} = $class;
    $Class2rdf_type{$class} = $uri;
}

our $AUTOLOAD;

sub AUTOLOAD {
    my $mth = $AUTOLOAD;
    $mth =~ s/.*:://;
    my $self = shift;
    if (@_) {
        return $self->set($mth => @_);
    }
    else {
        return $self->get($mth);
    }
}

1;
