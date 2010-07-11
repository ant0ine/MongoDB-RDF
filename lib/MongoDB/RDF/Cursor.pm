package MongoDB::RDF::Cursor;
use strict;
use warnings;

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

=head2 count

=cut

sub count {
    my $self = shift;    
    return $self->cursor->count(@_);
}

1;
