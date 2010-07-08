
use Test::More tests => 4;
use strict;

use Data::Dumper;

use MongoDB;
use MongoDB::RDF;

my $mrdf = MongoDB::RDF->new(
    database => MongoDB::Connection->new(host => 'localhost', port => 27017)->test_rdf
);
isa_ok($mrdf, 'MongoDB::RDF');

my $graph = $mrdf->default_graph;
isa_ok($graph, 'MongoDB::RDF::Graph');

# extra graph
my $extra_graph = $mrdf->get_graph('extra');
isa_ok($graph, 'MongoDB::RDF::Graph');

# RDF JSON export
my $r = MongoDB::RDF::Resource->new('http://example.org/0');
$r->dc_title('my title');
cmp_ok($r->as_rdf_json, 'eq', '{"http://example.org/0":{"http://purl.org/dc/elements/1.1/title":[{"value":"my title","type":"literal"}]}}', 'RDF JSON export');

=cut

$r->as_ntriples;
$r->as_rdf_xml;

=cut

