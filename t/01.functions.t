use Test::More tests => 14;

use lib '../lib';

# TODO: get it to work with 'my $name = 'Dan'; instead of:
use vars qw($name);
$name   = 'Dan';

BEGIN {
    use_ok( 'Interpolate', qw(interpolate interpolate_clone) );
}

diag( "Testing Interpolate $Interpolate::VERSION functions" );

my $string = 'Hello $name';
my @array  = ('Hello $name', 'Goodbye $name');
my %hash   = (
   'one' => 'Hello $name',
   'two' => 'Goodbye $name',
);

ok( interpolate('Hello $name') eq 'Hello Dan', 'simple string' );

ok( ${ interpolate_clone( \$string ) } eq 'Hello Dan', 'simple string ref copy' );
ok( interpolate_clone( \@array )->[1] eq 'Goodbye Dan', 'simple array ref copy' );
ok( interpolate_clone( \%hash )->{'two'} eq 'Goodbye Dan', 'simple hash ref copy' );

ok( $string eq 'Hello $name', 'string ref unchanged' );
ok( $array[1] eq 'Goodbye $name', 'array ref unchanged' );
ok( $hash{'two'} eq 'Goodbye $name', 'hash ref unchanged' );

ok( ${ interpolate( \$string ) } eq 'Hello Dan', 'simple string ref' );
ok( interpolate( \@array )->[1] eq 'Goodbye Dan', 'simple array ref' );
ok( interpolate( \%hash )->{'two'} eq 'Goodbye Dan', 'simple hash ref' );

ok( $string eq 'Hello Dan', 'string ref changed' );
ok( $array[1] eq 'Goodbye Dan', 'array ref changed' );
ok( $hash{'two'} eq 'Goodbye Dan', 'hash ref changed' );