package MongoDB::RDF::Graph;
use strict;
use warnings;

use MongoDB;
use MongoDB::OID;

use MongoDB::RDF::Util qw( canonical_uri fencode fdecode convert_query );
use MongoDB::RDF::Namespace qw( resolve );
use MongoDB::RDF::Cursor;

=head2 new( name => ..., mrdf => ... )

=cut

sub new {
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
    return $self;
}

=head2 name

Returns the graph name.

=cut

sub name { $_[0]->{name} }

sub _mrdf { $_[0]->{mrdf} }

=head2 collection

Gives you direct access to the MongoDB::Collection hidden behind the graph.

=cut

sub collection {
    my $self = shift;
    my $name = $self->name;
    return $self->_mrdf->database->$name();
}

=head2 load( $uri )

Loads a resource from the graph.
If this resource has a registered rdf_type, then this resource 
will be reblessed to the corrsponding class.
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

=head2 load_by_mongodb_id( $id )

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

=head2 save( $resource )

Saves a resource in the graph.

=cut

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

=head2 remove( $resource )

removes a resource from the graph.

=cut

sub remove {
    my $self = shift;
    my ($resource) = @_;
    my $c = $self->collection;
    return $c->remove({ _subject => $resource->subject });
}

=head2 find

=cut

sub find {
    my $self = shift;
    my ($query) = @_;
    convert_query($query);
    my $c = $self->collection;
    my $cursor = $c->find($query);
    return MongoDB::RDF::Cursor->new($cursor);
}

=head2 find_class

=cut

sub find_class {
    my $self = shift;
    my ($class, $query) = @_;
    if (my $type = MongoDB::RDF::Resource->_class_to_rdf_type($class)) {
        $query->{rdf_type} = $type;
    }
    return $self->find($query);
}

=head2 ensure_index

=cut

sub ensure_index {
    my $self = shift;
    my ($fields, $opts) = @_;
    for my $key (keys %$fields) {
        my $value = delete $fields->{$key};
        $key = fencode(resolve($key)).'.value';
        $fields->{$key} = $value;
    }
    my $c = $self->collection;
    $c->ensure_index($fields, $opts);
}

1;
