use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MongoDB::RDF',
    license             => 'perl',
    dist_author         => q{Antoine Imbert <antoine.imbert@gmail.com>},
    dist_version_from   => 'lib/MongoDB/RDF.pm',
    build_requires => {
        'Test::More' => 0,
        'JSON::Any' => 0,
        'URI' => 0,
        'MongoDB' => 0,
    },
    add_to_cleanup      => [ 'MongoDB-RDF-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
