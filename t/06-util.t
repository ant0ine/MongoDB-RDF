
use Test::More tests => 5 + 5 + 4;
use strict;

use Data::Dumper;

use MongoDB;
use MongoDB::RDF::Util qw( looks_like_uri canonical_uri );


# looks_like_uri

my @valid_uris = (
    'http://example.org',
    'https://example.org',
    'ftp://example.org',
    'urn:app:user',
    'a1:example.org',
);

for (@valid_uris) {
    ok looks_like_uri($_);
}

my @invalid_uris = (
    'http://example.org/test index.html',
    '1http://example.org',
    '!http://example.org',
    '_http://example.org',
    ' http://example.org',
);

for (@invalid_uris) {
    ok !looks_like_uri($_);
}

my %canonicals = (
    'http://example.org/test index.html' => 'http://example.org/test%20index.html',
    ' http://example.org' => 'http://example.org/',
    'HTTP://example.org' => 'http://example.org/',
    'http://example.org//' => 'http://example.org//',
);

for (keys %canonicals) {
    my $expected = $canonicals{$_};
    cmp_ok( canonical_uri($_), 'eq', $expected);
}

