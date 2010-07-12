package MongoDB::RDF::Cursor;
use strict;
use warnings;

use MongoDB::RDF::Namespace qw( resolve );
use MongoDB::RDF::Util qw( canonical_uri fencode fdecode );

=head2 new

=cut

sub new {
    my $class = shift;
    my ($cursor) = @_;
    return bless { cursor => $cursor }, $class;
}

=head2 cursor

Returns the underlying MongoDB::Cursor

=cut

sub cursor { $_[0]->{cursor} }

=head2 next

=cut

sub next {
    my $self = shift;    
    my $doc = $self->cursor->next;
    return unless $doc;
    return MongoDB::RDF::Resource->_new_from_document($doc);
}

=head2 all

=cut

sub all {
    my $self = shift;
    return map {
        MongoDB::RDF::Resource->_new_from_document($_)
    } $self->cursor->all;
}

sub _proxy {
    my $self = shift;
    my $mtd = shift;
    $self->cursor->$mtd(@_);
    return $self;
}

=head2 count

=cut

sub count { shift->cursor->count(@_) }

=head2 has_next

=cut

sub has_next { shift->cursor->has_next(@_) }

=head2 reset

=cut

sub reset { shift->cursor->reset(@_) }

=head2 explain

=cut

sub explain { shift->cursor->explain(@_) }

=head2 snapshot

=cut

sub snapshot { shift->cursor->snapshot(@_) }

=head2 skip

Proxy to MongoDB::Cursor::skip. Returns a MongoDB::RDF::Cursor.

=cut

sub skip { shift->_proxy(skip => @_) }

=head2 limit

Proxy to MongoDB::Cursor::limit. Returns a MongoDB::RDF::Cursor.

=cut

sub limit { shift->_proxy(limit => @_) }

=head2 sort

TODO explain why it sort by the first value of the predicate.

=cut

sub sort { 
    my $self = shift;
    my ($order) = @_;

    for my $key (keys %$order) {
        my $value = delete $order->{$key};
        $key = fencode(resolve($key)).'.0.value';
        $order->{$key} = $value;
    }

    $self->_proxy('sort' => $order);
}

=head2 hint

TODO

=cut

sub hint { shift->cursor->hint(@_) }

1;
