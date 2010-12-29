
use Test::More tests => 25;
use strict;
use warnings;

use Data::Dumper;

use MongoDB;
use MongoDB::RDF;

my $mrdf = MongoDB::RDF->new(
    database => MongoDB::Connection->new(host => 'localhost', port => 27017)->test_rdf
);
isa_ok($mrdf, 'MongoDB::RDF');

my $graph = $mrdf->default_graph;
isa_ok($graph, 'MongoDB::RDF::Graph');

note 'new resource';
my $r = MongoDB::RDF::Resource->new('http://example.org/0');
isa_ok($r, 'MongoDB::RDF::Resource');

not 'set';
ok $r->dc_title('my title');
ok $r->rss_link('http://example.org/1', 'http://example.org/2');
my $ref = {
'http://purl.org/rss/1.0/link' => [
  {
    'value' => 'http://example.org/1',
    'type' => 'uri'
  },
  {
    'value' => 'http://example.org/2',
    'type' => 'uri'
  }
],
'http://purl.org/dc/elements/1.1/title' => [
  {
    'value' => 'my title',
    'type' => 'literal'
  }
]
};
is_deeply($r->properties, $ref, 'properties')
    or print STDERR Dumper($r->properties);

note 'del';
ok $r->del(rss_link => 'http://example.org/2');
is_deeply($r->properties, {
'http://purl.org/rss/1.0/link' => [
  {
    'value' => 'http://example.org/1',
    'type' => 'uri'
  },
],
'http://purl.org/dc/elements/1.1/title' => [
  {
    'value' => 'my title',
    'type' => 'literal'
  }
]
}, 'properties')
    or print STDERR Dumper($r->properties);

# removing all the elements of the property remove this property
ok $r->del(rss_link => 'http://example.org/1');
is_deeply($r->properties, {
'http://purl.org/dc/elements/1.1/title' => [
  {
    'value' => 'my title',
    'type' => 'literal'
  }
]
}, 'properties')
    or print STDERR Dumper($r->properties);

note 'add';
ok $r->add(rss_link => 'http://example.org/1');
ok $r->add(rss_link => 'http://example.org/2');
is_deeply($r->properties, $ref, 'properties')
    or print STDERR Dumper($r->properties);

note 'get ';
my @links = $r->rss_link;
is_deeply(\@links, ['http://example.org/1', 'http://example.org/2'], 'links');
my $link = $r->rss_link;
is_deeply($link, 'http://example.org/1', 'link');

note 'save';
ok $graph->save($r);

note 'load';
my $r2 = $graph->load('http://example.org/0');
isa_ok($r2, 'MongoDB::RDF::Resource');
is_deeply($r2->properties, $ref, 'properties')
    or print STDERR Dumper($r2->properties);

note 'remove';
$graph->remove($r2);

note 'load missing';
my $r3 = $graph->load('http://example.org/0');
ok(!$r3, 'has been removed');

note 'blank nodes';
my $blank = MongoDB::RDF::Resource->new;
isa_ok($blank, 'MongoDB::RDF::Resource');
ok($blank->uri, 'has a uri');

note 'save';
ok $graph->save($blank);

my $blank2 = $graph->load($blank->uri);
isa_ok($blank2, 'MongoDB::RDF::Resource');
ok($blank2->uri, 'has a uri');
cmp_ok( $blank->mongodb_id, 'eq', $blank2->mongodb_id, 'same mongodb_id');

note 'remove';
$graph->remove($blank);

