package MongoDB::RDF::Util;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw( canonical_uri fencode fdecode );

use URI;

=head2 canonical_uri

=cut

sub canonical_uri {
    my ($uri) = @_;
    return URI->new($uri)->canonical->as_string;
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

1;
