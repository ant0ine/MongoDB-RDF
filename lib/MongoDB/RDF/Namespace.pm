package MongoDB::RDF::Namespace;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw( resolve );

use MongoDB::RDF::Util qw( canonical_uri );

# in memory not in a mongo collection
# this keeps mongo agnostic about the namespace used

my %Ns = (
    dc      => 'http://purl.org/dc/elements/1.1/',
    rdf     => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
    foaf    => 'http://xmlns.com/foaf/0.1/',
    rss     => 'http://purl.org/rss/1.0/',
);

=head2 resolve

=cut

sub resolve {
    my ($local) = @_;
    if ($local =~ /^([a-zA-Z0-9]+)[:_](\w+)$/) {
        my $prefix = lc($1);
        my $name = $2;
        if (my $uri = $Ns{$prefix} ) {
            return $uri.$name;
        }
    }
    return $local; 
}

=head2 register

=cut

sub register {
    my $class = shift;
    my ($prefix, $uri) = @_;
    die 'prefix required' unless $prefix;
    die 'uri required' unless $uri;
    $uri = canonical_uri($uri);
    $prefix = lc($prefix);
    $Ns{$prefix} = $uri;
    return 1;
}

1;
