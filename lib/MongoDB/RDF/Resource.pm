package MongoDB::RDF::Resource;
use strict;
use warnings;

use JSON::Any;

use MongoDB::RDF::Namespace qw( resolve );
use MongoDB::RDF::Util qw( canonical_uri fencode fdecode );

my %Rdf_type2class;
my %Class2rdf_type;

=head2 register_rdf_type

=cut

sub register_rdf_type {
    my $class = shift;
    my ($uri) = @_;
    # TODO check $class
    # TODO check $uri 
    $Rdf_type2class{$uri} = $class;
    $Class2rdf_type{$class} = $uri;
}

=head2 new

=cut

sub new {
    my $class = shift;
    my ($subject) = @_;
    die "subject required" unless $subject;
    my $self = bless {
        document => {},
    }, $class;
    $self->subject($subject);
    if (my $type = $Class2rdf_type{$class}) {
        $self->set(rdf_type => $type);    
    }
    return $self;
}

=head2 subject

=cut

sub subject {
    my $self = shift;    
    my ($uri) = @_;
    if ($uri) {
        $self->{document}{_subject} = canonical_uri($uri);
    }
    return $self->{document}{_subject};
}

=head2 document

Returns the document as stored in MongoDB.

=cut

sub document { $_[0]->{document} }

=head2 new_from_document

Should be private ? as document ?

=cut

sub new_from_document {
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
    my $type = $value =~ /^[a-zA-Z]\w+:/ ? 'uri' : 'literal';
    $value = canonical_uri($value) if $type eq 'uri';
    return { type => $type, value => $value };
}

sub _object2value {
    my $self = shift;    
    my ($object) = @_;
    return $object->{value};
}

=head2 get

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

=head2 add

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

=head2 del

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

=head2 set

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

=head2 as_rdf_json

=cut

sub as_rdf_json {
    my $self = shift;    
    my $obj = {
        $self->subject => $self->properties( decoded => 1 )
    };
    my $j = JSON::Any->new; 
    return $j->objToJson($obj);
}

=head2 as_rdf_xml

=cut

sub as_rdf_xml {
    my $self = shift;    
    # TODO 
}

=head2 as_ntriples

=cut

sub as_ntriples {
    my $self = shift;    
    # TODO 
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
