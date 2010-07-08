
use Test::More tests => 16;
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

# new resource
my $r = MongoDB::RDF::Resource->new('http://example.org/0');
isa_ok($r, 'MongoDB::RDF::Resource');

# set
ok $r->dc_title('my title');
ok $r->rss_link('http://example.org/1', 'http://example.org/2');
my $ref = {
'http://purl%2Eorg/rss/1%2E0/link' => [
  {
    'value' => 'http://example.org/1',
    'type' => 'uri'
  },
  {
    'value' => 'http://example.org/2',
    'type' => 'uri'
  }
],
'http://purl%2Eorg/dc/elements/1%2E1/title' => [
  {
    'value' => 'my title',
    'type' => 'literal'
  }
]
};
is_deeply($r->properties, $ref, 'properties')
    or print STDERR Dumper($r->properties);

# del
ok $r->del(rss_link => 'http://example.org/2');
is_deeply($r->properties, {
'http://purl%2Eorg/rss/1%2E0/link' => [
  {
    'value' => 'http://example.org/1',
    'type' => 'uri'
  },
],
'http://purl%2Eorg/dc/elements/1%2E1/title' => [
  {
    'value' => 'my title',
    'type' => 'literal'
  }
]
}, 'properties')
    or print STDERR Dumper($r->properties);

# add
ok $r->add(rss_link => 'http://example.org/2');
is_deeply($r->properties, $ref, 'properties')
    or print STDERR Dumper($r->properties);

# get 
my @links = $r->rss_link;
is_deeply(\@links, ['http://example.org/1', 'http://example.org/2'], 'links');
my $link = $r->rss_link;
is_deeply($link, 'http://example.org/1', 'link');

# save
ok $graph->save($r);

# load
my $r2 = $graph->load('http://example.org/0');
isa_ok($r2, 'MongoDB::RDF::Resource');
is_deeply($r2->properties, $ref, 'properties')
    or print STDERR Dumper($r2->properties);

# remove
$graph->remove($r2);

# load missing
my $r3 = $graph->load('http://example.org/0');
ok(!$r3, 'has been removed');


