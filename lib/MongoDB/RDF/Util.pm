package MongoDB::RDF::Util;
use strict;
use warnings;

use MongoDB::RDF::Namespace;

use Exporter 'import';
our @EXPORT_OK = qw( canonical_uri looks_like_uri fencode fdecode convert_query );

use URI;

=head2 canonical_uri

MongoDB::RDF stores in the documents the URI in their canonical form.

=cut

sub canonical_uri {
    my ($uri) = @_;
    return URI->new($uri)->canonical->as_string;
}

=head2 looks_like_uri

Returns 1 if this looks like a URI.
(Not a strict validation)

=cut

sub looks_like_uri {  # XXX we may want to not guess, and assume that the value is a canonical uri
    return $_[0] =~ /^[a-zA-Z]\w+:\S+$/;
}

=head2 fencode

MongoDB doesn't allow '.' in the field names.
As the fields names here are URIs, we just encode the '.' to '%2E'

=cut

sub fencode {
    my ($uri) = @_;
    $uri =~ s/\./%2E/g;
    return $uri;
}

=head2 fdecode

Opposite of fencode.

=cut

sub fdecode {
    my ($uri) = @_;
    $uri =~ s/%2E/\./g;
    return $uri;
}

=head2 convert_query

=cut

sub convert_query {
    my ($q) = @_;
    my $convert_q;
    $convert_q = sub {
        my ($query) = @_;
        for my $key (keys %$query) {
            # make this recursive in this case
            if ($key eq '$or') {
                $convert_q->($_) for @{ $query->{$key} };
            }
            else {
                my $value = delete $query->{$key};
                $key = fencode(MongoDB::RDF::Namespace::resolve($key)).'.value';
                # TODO $elemMatch or dotnotation ?
                $query->{$key} = $value;
            }
        }
        return $query;
    };
    return $convert_q->($q);
}

1;
