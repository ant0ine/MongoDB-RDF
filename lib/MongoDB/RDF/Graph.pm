package MongoDB::RDF::Graph;
use strict;
use warnings;

use Tie::IxHash;
use MongoDB;
use MongoDB::OID;

use MongoDB::RDF::Util qw( canonical_uri fencode fdecode convert_query );
use MongoDB::RDF::Namespace qw( resolve );
use MongoDB::RDF::Cursor;

=head1 NAME

MongoDB::RDF::Graph

=head1 SYNOPSIS

=head1 DESCRIPTION

This is the place where to save, load, delete and find a set of resources.
This is mapped to a MongoDB Collection.

=cut

sub _new {
    my $class = shift;
    my %args = @_;
    my $self = bless {}, $class;
    for (qw(name mrdf)) {
        die "$_ required" unless $args{$_};    
        $self->{$_} = $args{$_};
    }
    # TODO maintain a global cache of the ensured indexes
    # the cost of ensure_index may not be negligable 
    $self->collection->ensure_index({ _subject => 1 }, { unique => 1 });
    $self->ensure_index({ rdf_type => 1 });
    return $self;
}

sub _mrdf { $_[0]->{mrdf} }

=head1 METHODS

=head2 $self->name

Returns the graph name.

=cut

sub name { $_[0]->{name} }

=head2 $self->load( $uri )

Loads a resource from the graph.
If this resource has a registered rdf_type, then this resource 
will be reblessed to the corresponding class.
(See MongoDB::RDF::Resource->register_rdf_type)

=cut

sub load {
    my $self = shift;
    my $uri = shift or die 'uri required';
    $uri = canonical_uri($uri);
    my $c = $self->collection;
    my $doc = $c->find_one(
        { _subject => $uri },
    );
    return unless $doc;
    return MongoDB::RDF::Resource->_new_from_document($doc);
}

=head2 $self->save( $resource )

Saves a resource in the graph.

=cut

# TODO, would be nice to update the object with the new mongodb_id

sub save {
    my $self = shift;
    my ($resource) = @_;
    my $c = $self->collection;
    return $c->update(
        { _subject => $resource->subject },
        $resource->document,
        { upsert => 1 }
    );
}

=head2 $self->remove( $resource )

Removes a resource from the graph.

=cut

sub remove {
    my $self = shift;
    my ($resource) = @_;
    my $c = $self->collection;
    return $c->remove({ _subject => $resource->subject });
}

=head2 $self->find( { ... } )

Finds resources in the graph.
Returns a MongoDB::RDF::Cursor.

=cut

sub find {
    my $self = shift;
    my ($query) = @_;
    convert_query($query);
    my $c = $self->collection;
    my $cursor = $c->find($query);
    return MongoDB::RDF::Cursor->new($cursor);
}

=head2 $self->find_class( 'MyClass' => { ... } )

Similar to the "find" method except that specifying the class automatically
add the ritgh rdf_type term in your query.
Returns a MongoDB::RDF::Cursor.

=cut

sub find_class {
    my $self = shift;
    my ($class, $query) = @_;
    if (my $type = MongoDB::RDF::Resource->_class_to_rdf_type($class)) {
        $query->{rdf_type} = $type;
    }
    return $self->find($query);
}

=head2 $self->ensure_index( { $predicate => 1 }, $opt )

Create the index if it does not already exist.
Note that rdf_type and _subject already have an index defined.

Example:

 $self->ensure_index( { dc_title => 1 } )
 $self->ensure_index( { dc_title => 1 }, { unique => 1 } )
 $self->ensure_index( Tie::IxHash->new( dc_title => 1, dc_date => 1 ) )

=cut

sub ensure_index {
    my $self = shift;
    my ($fields, $opts) = @_;
    $fields = Tie::IxHash->new(%$fields)
        if ref $fields eq 'HASH';

    for (my $i=0; $i<$fields->Length; $i++) {
        my $key = $fields->Keys($i);
        my $value = $fields->Values($i);
        $key = fencode(resolve($key)).'.value';
        $fields->Replace($i, $value, $key);
    }

    my $c = $self->collection;
    $c->ensure_index($fields, $opts);
}

=head1 ACCESSING UNDERLYING MONGODB OBJECTS.

=head2 $self->collection

Gives you direct access to the MongoDB::Collection hidden behind the graph.

=cut

sub collection {
    my $self = shift;
    my $name = $self->name;
    return $self->_mrdf->database->$name();
}

=head2 $self->load_by_mongodb_id( $id )

=cut

sub load_by_mongodb_id {
    my $self = shift;
    my $id = shift or die 'id required';
    my $oid = MongoDB::OID->new( value => $id );
    my $c = $self->collection;
    my $doc = $c->find_one(
        { _id => $oid },
    );
    return unless $doc;
    return MongoDB::RDF::Resource->_new_from_document($doc);
}

1;
