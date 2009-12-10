use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CouchDB::Trackable',
    AUTHOR              => 'James E. Marca <jmarca@translab.its.uci.edu>',
    VERSION_FROM        => 'lib/CouchDB/Trackable.pm',
    ABSTRACT_FROM       => 'lib/CouchDB/Trackable.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Class::Sugar' => 0,
        'DB::Connection' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CouchDB-Trackable-*' },
);
