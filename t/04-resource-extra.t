
use Test::More tests => 9;
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
ok $graph->save($r);
cmp_ok($r->as_rdf_json, 'eq', '{"http://example.org/0":{"http://purl.org/dc/elements/1.1/title":[{"value":"my title","type":"literal"}]}}', 'RDF JSON export');

# get the OID
my $id = $graph->load('http://example.org/0')->mongodb_id;
ok $id;

# load by OID
my $r2 = $graph->load_by_mongodb_id($id);
isa_ok($r2, 'MongoDB::RDF::Resource');
cmp_ok($r->uri, 'eq', $r2->uri, 'same resource');

=cut

$r->as_ntriples;
$r->as_rdf_xml;

=cut

ok $graph->remove($r);
