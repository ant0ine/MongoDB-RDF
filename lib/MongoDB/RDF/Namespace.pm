package MongoDB::RDF::Namespace;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw( resolve );

# TODO put that in a Mongo Collection
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
        if ($Ns{$1} ) {
            return $Ns{$1}.$2;
        }
    }
    return $local; 
}

1;
