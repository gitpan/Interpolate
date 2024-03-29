use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Interpolate',
    AUTHOR              => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM        => 'lib/Interpolate.pm',
    ABSTRACT_FROM       => 'lib/Interpolate.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'              => 0,
        'version'                 => 0,
        'Local::Maketext::Pseudo' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Interpolate-*' },
);
