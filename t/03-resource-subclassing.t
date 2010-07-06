
package MyClass;
use strict;
use base qw( MongoDB::RDF::Resource );

__PACKAGE__->register_rdf_type( 'http://example.org/type1' );

1;

package main;
use Test::More tests => 10;
use strict;

use Data::Dumper;

use MongoDB;
use MongoDB::RDF;

my $mrdf = MongoDB::RDF->new(
    database => MongoDB::Connection->new(host => 'localhost', port => 27017)->test_db
);
isa_ok($mrdf, 'MongoDB::RDF');

my $graph = $mrdf->default_graph;
isa_ok($graph, 'MongoDB::RDF::Graph');


# new
my $r = MyClass->new('http://example.org/sub/0');
isa_ok($r, 'MongoDB::RDF::Resource');
isa_ok($r, 'MyClass');
cmp_ok($r->rdf_type, 'eq', 'http://example.org/type1');
ok $r->dc_title('my title');
ok $graph->save($r);

# load
my $r2 = $graph->load('http://example.org/sub/0');
isa_ok($r, 'MongoDB::RDF::Resource');
isa_ok($r, 'MyClass');
cmp_ok($r->rdf_type, 'eq', 'http://example.org/type1');

# remove
$graph->remove($r2);

