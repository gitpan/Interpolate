use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Interpolate',
    license             => 'perl',
    dist_author         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from   => 'lib/Interpolate.pm',
    requires => {
        'Test::More'              => 0,
        'version'                 => 0,
        'Local::Maketext::Pseudo' => 0.0.2,
    },
    add_to_cleanup      => [ 'Interpolate-*' ],
);

$builder->create_build_script();
