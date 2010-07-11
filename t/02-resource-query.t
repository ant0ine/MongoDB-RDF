
use Test::More tests => 27;
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

{
    # new resource
    my $r = MongoDB::RDF::Resource->new('http://example.org/0');
    isa_ok($r, 'MongoDB::RDF::Resource');
    ok $r->dc_title('my title');
    ok $r->rss_link('http://example.org/1', 'http://example.org/2');
    ok $graph->save($r);

    # find it by title
    my $cursor = $graph->find({ dc_title => 'my title' });
    isa_ok($cursor, 'MongoDB::RDF::Cursor');
    isa_ok($cursor->cursor, 'MongoDB::Cursor');
    cmp_ok($cursor->count, '==', 1, 'one result');
    my $r2 = $cursor->next;
    isa_ok($r2, 'MongoDB::RDF::Resource');
    cmp_ok($r->subject, 'eq', $r2->subject, 'same resource');
    ok(! $cursor->next, 'only one result');

    # creating again the same resource
    my $r3 = MongoDB::RDF::Resource->new('http://example.org/0');
    isa_ok($r3, 'MongoDB::RDF::Resource');
    ok $r3->dc_title('my title');
    ok $r3->rss_link('http://example.org/1', 'http://example.org/2');
    ok $graph->save($r3);

    # as subject is a unique index
    # we should still have one resource
    my $cursor2 = $graph->find({ dc_title => 'my title' });
    isa_ok($cursor2, 'MongoDB::RDF::Cursor');
    cmp_ok($cursor2->count, '==', 1, 'one result');

    # remove
    $graph->remove($r);
}

{
    my @res;
    for (1..10) {
        my $r = MongoDB::RDF::Resource->new('http://example.org/'.$_);
        $r->dc_title('my title');
        $r->dc_description($_);
        $graph->save($r);
        push @res, $r;
    }

    # skip and limit
    my $cursor = $graph->find({ dc_title => 'my title' });
    isa_ok($cursor, 'MongoDB::RDF::Cursor');
    isa_ok($cursor->cursor, 'MongoDB::Cursor');

    cmp_ok($cursor->count, '==', 10, '10 results');
    $cursor->skip(2);
    cmp_ok($cursor->count(1), '==', 8, '8 results');
    $cursor->limit(4);
    cmp_ok($cursor->count(1), '==', 4, '4 results');
    cmp_ok($cursor->count, '==', 10, '10 results');
    my @subset = $cursor->all;
    cmp_ok(scalar(@subset), '==', 4, '4 results');

    # reset
    $cursor->reset;
    @subset = $cursor->limit(2)->skip(3)->all;
    cmp_ok(scalar(@subset), '==', 2, '2 results');
    
    # or
    my $query = { '$or' => [
        { dc_description => 1 },
        { dc_description => 2 },
        { dc_description => 3 },
    ] };
    @subset = $graph->find($query)->all;
    cmp_ok(scalar(@subset), '==', 3, '3 results');

    $graph->remove($_) for @res;
}
