package Interpolate;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.1');
use Locale::Maketext::Pseudo qw(env_maketext);
use base 'Exporter';
our @EXPORT_OK = qw(interpolate interpolate_clone);

sub interpolate {
    my ($string, $pkg, $seen) = @_;
    
    $pkg = caller if !$pkg;

    if( ref $string ) {
        $seen = {} if ref $seen ne 'HASH';
        $seen->{ $string }++;
        if( $seen->{ $string } > 1 ) {
            carp env_maketext('Skipping already interpolated reference (circular refs)'); 
        }
        else {
            return _interpolate_ref( $string, $pkg, $seen );
        }
    }
    else {
        return _interpolate_str( $string, $pkg );
    }
}

sub interpolate_clone {
    my ($string, $pkg, $seen) = @_;
    
    $pkg = caller if !$pkg;
    
    my $type = ref $string;
    if( $type ) {
        if( $type eq 'HASH' ) {
            my %tmp = %{ $string };
            $string = \%tmp;
        }
        elsif( $type eq 'ARRAY' ) {
            my @tmp = @{ $string };
            $string = \@tmp;            
        }
        elsif( $type eq 'SCALAR' ) {
            my $tmp = ${ $string };
            $string = \$tmp;            
        }
        elsif( $string->can('interpolate_clone') ) {
            $string = $string->interpolate_clone( $pkg, $seen );
        }
    }
    
    if( $type ) {
        return _interpolate_ref( $string, $pkg, $seen );
    }
    else {
        return _interpolate_str( $string, $pkg );
    }
}

sub _interpolate_str {
    my ( $string, $pkg ) = @_;
 
    my $here = rand; 
    while( $string =~ m{$here} ) {
        $here = rand; 
    }
    
    my $str  = eval qq{
package $pkg;
    return <<"$here";
$string
$here
package Interpolate;
    };

    chomp $str; 
    return $str;    
}

sub _interpolate_ref {
    my ($ref, $pkg, $seen) = @_;

    my %types = (
        'SCALAR' => sub {
            my ($scalarref, $pkg, $seen) = @_;
            ${ $scalarref } =  interpolate( ${ $scalarref }, $pkg, $seen );
            return $scalarref;  
        },
        'ARRAY'  => sub {
            my ($arrayref, $pkg, $seen) = @_;    
            for my $idx (0 .. scalar( @{ $arrayref }) - 1 ) {
                $arrayref->[ $idx ] = interpolate( $arrayref->[ $idx ], $pkg, $seen );
            }
            return $arrayref;
        },
        'HASH'   => sub {
            my ($hashref, $pkg, $seen) = @_;
            for my $key ( keys %{ $hashref }) {
                $hashref->{ $key } = interpolate( $hashref->{ $key }, $pkg, $seen );
            }
            return $hashref;            
        },
    );
    
    $seen->{ $ref }++;
    if( exists $types{ ref $ref }) {
        return $types{ ref $ref }->( $ref, $pkg, $seen );
    }
    elsif( $ref->can('interpolate') ) {
        return $ref->interpolate( $pkg, $seen );
    }
    else {
        carp env_maketext('Skipping unknown reference type');
    }
}

1; 

__END__

=head1 NAME

Interpolate - Interpolate a variable or reference contents safely and quickly

=head1 VERSION

This document describes Interpolate version 0.0.1

=head1 SYNOPSIS

    use Interpolate;

    my $name     = $prm->param('name') || 'World'; # '$prm' = CGI::Simple or Getopt::Param obj
    my $greeting = 'Hello $name'; # literal string
    
    print interpolate( $greeting ); # Hello Bean || Hello World

=head1 DESCRIPTION

Interpolate variables in the argument as if it were double quoted.

Perhaps the SYNOPSIS example is a bit pointless but imagine if the 'greeting' was 
had from a file, database, etc and it used scalars, arrays, and hashes?

Additionally, its safer than

   eval $variable;

because if variable contained code itd get executed. (IE pronounced "bad idea to eval external code since it could be malicious")

With interpolate() it'd simply return the interpolated "string": CODE(0x180b3bc)

Its also fast, no weird algorythm trying to parse and ferdiddle it to mimic how perl does interpolation. It just asks very politley if perl would be so kind as to have a peek and tell us what it thinks :) 

=head1 INTERFACE 

The interface was made to be safe, simple, and intuitive

Tip: set $ENV{'maketext_obj'} to an object that can() maketext(), see "LOCALIZATION" below and L<Locale::Maketext::Pseudo>

=head2 interpolate()

Besides a string that has variables in it to be interpolated you can also pass class references also if the class has an interpolate method. 

    my $objmethod_returnvalue = interplolate( $obj );

If it does then its called with an argument that is a hashref that shows what ref's have already been seen, including itself.

    package Example; 

    sub interoplate {
        my ($self, $orig_caller, $seen_hashref) = @_;
        # do whatevr it means to interpolate $self for this class...
        # return whatever makes sense if anything...
    }
        

=head2 interpolate_clone()

Same as interpolate() except it clones the reference argument first and modifies that instead of the original.

The new "clone" is returned for your use:

   my $interpolated_hashref   = interpolate_clone( $orig_hashref );
   my $interpolated_arrayref  = interpolate_clone( $orig_arrayref );
   my $interpolated_scalarref = interpolate_clone( $orig_scalarref );

You can pass class references also if the class has an interpolate_clone method. 

    my $objmethod_returnvalue = interplolate_clone( $obj );

If it does then its called with the same as interploate arguments and should return an object suitable to be 
$self->interpolate()'ed or '' or the interpolated string or whatver makes sensefor the object

    package Example; 

    sub interoplate_clone {
        my ($self, $orig_caller, $seen_hashref) = @_;
        return $self->is_cloneable() ? $self->clone() : '';
    }


=head1 BASIC TEMPLATING

Cool, so I could put strings with variables in a database or files and use 
them to template something, great! but...

Q: How do I include dynamic stuff?

A: The same way you would with data in a here doc:

You could tie a variable:

    # Assuming $time is tied to time():
    
    my $first  = get_lyrics(1); # q{You're older than you've even been ($time)}
    my $repeat = get_lyrics(2); # q{and now you're even older ($time)'}
    my $last   = get_lyrics(3); # q{and now you're older still ($time)}
    
    print interpolate( $first );
    sleep 1;     
    for (1..3) {
        print interpolate( $repeat );
        sleep 1;     
    }
    print interpolate( $first );
    sleep 1;
    print interpolate( $repeat );
    sleep 1;
    print interpolate( $last );

See L<SimpleMood> for more great variables that do this sort of thing already!

Also in the L<SimpleMood> spirit, for more complex tasks, I prefer to use a single 
hash whose keys are the name and the values are coderefs that get executed when FETCH'ed.

    my $functions = {
        'list_users' => sub {
            my ($template_str) = @_;
            formy $user ( _get_users() ) {
                $template_str =~ s{\[\% user \%\]}{$user}g;
            }
            return $template_str;
        },
    }
   
    ...
    
    my $showusers = _get_show_users_str(); # q(Here are your users:<br />$functions->{'list_users'}{'<p>[% user %]</p>'})
    print interpolate( $showusers );

L<Interpolation> has a similar 'hash tie()ing' interface with more 'complexible'  (See 'complexible' in the 'Glossary of Terms' section of L<SimpleMood>) calling pardigm (yes I said 'paradigm' so what ;p) for all your ferdiddling needs.

=head1 LOCALIZATION

This module uses L<Locale::Maketext::Pseudo> as a default if nothing else is
specified to support localization in harmony with the apps using it.

See "DESCRIPTION" at L<Locale::Maketext::Pseudo> for more info on why this is
good and why you should use this module's language object support at best and,
at worst, appreciate it being there for when you will want it later.

=head1 DIAGNOSTICS

=over

=item C<< Skipping already interpolated reference (circular refs) >>

It has encountered a reference its already seen and is skipping it to avoid infinite loops.

=item C<< Skipping unknown reference type >>

It has encountered a reference that is not 'HASH', 'ARRAY', 'SCALAR', 
or does not itself have an interpolate() method.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Interpolate requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Local::Maketext::Pseudo>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-interpolate@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

The way it works currently the variables must be available in the BEGIN{} and use()

In other words you must:

   use vars qw($name);
   $name = 'Dan';
   print interpolate('My name is $name');

Instead of:
 
   my $name = 'Dan';
   print interpolate('My name is $name');

Yes, that really stinks and semi defeats the purpose and will be resolved in 0.0.2 (any input on how to do is appreciated ;p)

Hopefully the resolution for that will also allow the t/perlcritic.t test to not be skipped instead of:

    Expression form of "eval" at line 72, column 16.  See page 161 of PBP.  (Severity: 5)

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
