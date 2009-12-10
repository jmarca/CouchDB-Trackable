use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CouchDB::Trackable',
    license             => 'perl',
    dist_author         => 'James E. Marca <jmarca@translab.its.uci.edu>',
    dist_version_from   => 'lib/CouchDB/Trackable.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'CouchDB-Trackable-*' ],
);

$builder->create_build_script();
