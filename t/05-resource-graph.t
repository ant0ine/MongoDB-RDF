
use Test::More tests => 4;
use strict;

use Data::Dumper;

use MongoDB;
use MongoDB::RDF;

my $mrdf = MongoDB::RDF->new(
    database => MongoDB::Connection->new(host => 'localhost', port => 27017)->test_rdf
);

my $graph = $mrdf->default_graph;

# new resources
my $r0 = MongoDB::RDF::Resource->new('http://example.org/0');
$r0->rss_link('http://example.org/1');
$graph->save($r0);

my $r1 = MongoDB::RDF::Resource->new('http://example.org/1');
$r1->dc_title('my title');
$graph->save($r1);

my ($t1) = $r0->get_resources(rss_link => $graph);
isa_ok $t1, 'MongoDB::RDF::Resource';
cmp_ok( $t1->subject, 'eq', $r1->subject, 'found r1' );

my ($t0) = $r1->get_referer_resources(rss_link => $graph);
isa_ok $t0, 'MongoDB::RDF::Resource';
cmp_ok( $t0->subject, 'eq', $r0->subject, 'found r0' );

# remove
$graph->remove($r0);
$graph->remove($r1);


