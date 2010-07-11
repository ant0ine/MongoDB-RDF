
package MyClass;
use strict;
use base qw( MongoDB::RDF::Resource );

__PACKAGE__->register_rdf_type( 'http://example.org/type1' );

sub init {
    my $self = shift;
    $self->dc_title('my title');
}

1;

package main;
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


# new
my $r = MyClass->new('http://example.org/sub/0');
isa_ok($r, 'MongoDB::RDF::Resource');
isa_ok($r, 'MyClass');
cmp_ok($r->rdf_type, 'eq', 'http://example.org/type1');
cmp_ok($r->dc_title, 'eq', 'my title', 'init processed');
ok $graph->save($r);

# load
my $r2 = $graph->load('http://example.org/sub/0');
isa_ok($r2, 'MongoDB::RDF::Resource');
isa_ok($r2, 'MyClass');
cmp_ok($r2->rdf_type, 'eq', 'http://example.org/type1');
cmp_ok($r2->dc_title, 'eq', 'my title');

# find
my $cursor = $graph->find_class( MyClass => { dc_title => 'my title' } );
isa_ok($cursor, 'MongoDB::RDF::Cursor');
my $r3 = $cursor->next;
isa_ok($r3, 'MongoDB::RDF::Resource');
isa_ok($r3, 'MyClass');
cmp_ok($r3->rdf_type, 'eq', 'http://example.org/type1');
cmp_ok($r3->dc_title, 'eq', 'my title');

# remove
$graph->remove($r);

