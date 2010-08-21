#!perl -T

use Test::More tests => 8;

use_ok( 'MongoDB::RDF' );
use_ok( 'MongoDB::RDF::Namespace' );
use_ok( 'MongoDB::RDF::Util' );
use_ok( 'MongoDB::RDF::Graph' );
use_ok( 'MongoDB::RDF::Cursor' );
use_ok( 'MongoDB::RDF::Resource' );
use_ok( 'MongoDB::RDF::Serializer' );
use_ok( 'MongoDB::RDF::Serializer::NTriples' );

diag( "Testing MongoDB::RDF $MongoDB::RDF::VERSION, Perl $], $^X" );
