use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'gtl_read_filter_pipeline',
    license             => 'perl',
    dist_author         => q{Nick Youngblut <nyoungb2@illinois.edu>},
    dist_version_from   => 'lib/gtl_read_filter_pipeline.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup     => [ 'gtl_read_filter_pipeline-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
