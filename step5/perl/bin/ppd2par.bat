@rem = '--*-Perl-*--
@set "ErrorLevel="
@if "%OS%" == "Windows_NT" @goto WinNT
@perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
@set ErrorLevel=%ErrorLevel%
@goto endofperl
:WinNT
@perl -x -S %0 %*
@set ErrorLevel=%ErrorLevel%
@if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" @goto endofperl
@if %ErrorLevel% == 9009 @echo You do not have Perl in your PATH.
@goto endofperl
@rem ';
#!/usr/bin/perl
#line 16
use strict;
use warnings;

use Getopt::Long qw/GetOptions/;
use PAR::Dist::FromPPD;

our $VERSION = '0.01';

=pod

=head1 NAME

ppd2par - Create PAR distributions from PPD XML files

=head1 SYNOPSIS

ppd2par --help

ppd2par [-v -o DIR ...] -u PPD-URI-OR-FILE

=head1 DESCRIPTION

This script creates PAR distributions from packages for the
I<Perl Package Manager> which is specific to ActiveState's 
perl distributions. In order to do this, F<ppd2par> parses
a PPD document (which is XML). The PPD document
contains meta data and URIs for the actual F<.tar.gz> packages
of the PPM package.

=head2 Parameters

  -u --uri
    Set the place to fetch the .ppd file from. Can be an URL
    (http://..., https://..., ftp://...) or a local file.
  -v --verbose
    Sets the verbose mode.
  -o --out
    Sets the output directory. (default: .)
  --no-docs
    Strip all documentation (man pages, html documentation) from the
    resulting PAR distribution.
    (This step is carried out at the end. If something goes wrong,
     it will be skipped.)

You can also set various bits of meta data by hand:

  -n --distname
    Distribution name
  --dv --distversion
    Distribution version (Note: This is not -v!)
  -p --perlversion
    Perl version (can be set to 'any_version')
  -a --arch
    Architecture string (can be set to 'any_arch')
  --sa --selectarch
    Regexp for selecting the implementation based on architecture
  --sp --selectperl
    Regexp for selecting the implementation based on perl version

=head1 SEE ALSO

This tool is implemented using the L<PAR::Dist::FromPPD> module. Please
refer to that module's documentation for details on how this all works.

PAR has a mailing list, <par@perl.org>, that you can write to; send
an empty mail to <par-subscribe@perl.org> to join the list and
participate in the discussion.

Please send bug reports to <bug-par-dist-fromcpan@rt.cpan.org>.

The official PAR website may be of help, too: http://par.perl.org

For details on the I<Perl Package Manager>, please refer to ActiveState's
website at L<http://activestate.com>.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

my $usage = <<"HERE";
$0 --help          # for help

$0 [-v -o DIR --no-docs] -u PPD-URI-OR-FILE

This script creates PAR distributions from packages for the
Perl Package Manager which is specific to ActiveState's 
perl distributions. In order to do this, it parses
a PPD document (which is XML). The PPD document
contains meta data and URIs for the actual .tar.gz packages
of the PPM package.

-u --uri
  Set the place to fetch the .ppd file from. Can be an URL
  (http://..., https://..., ftp://...) or a local file.
-v --verbose
  Sets the verbose mode.
-o --out
  Sets the output directory. (default: .)
--no-docs
  Strip all documentation (man pages, html documentation) from the
  resulting PAR distribution.
  (This step is carried out at the end. If something goes wrong,
   it will be skipped.)

You can also set various bits of meta data by hand:
-n --distname
  Distribution name
--dv --distversion
  Distribution version (Note: This is not -v!)
-p --perlversion
  Perl version (can be set to 'any_version')
-a --arch
  Architecture string (can be set to 'any_arch')
--sa --selectarch
  Regexp for selecting the implementation based on architecture
--sp --selectperl
  Regexp for selecting the implementation based on perl version
HERE

my $uri;
my $outdir = '.';
my $v = 0;
my $nodocs = 0;
my $distname;
my $distversion;
my $arch;
my $perl;
my $sperl;
my $sarch;
GetOptions(
    'n|distname=s' => \$distname,
    'dv|distversion=s' => \$distversion,
    'a|arch=s' => \$arch,
    'p|perlversion=s' => \$perl,
    'sa|selectarch=s' => \$sarch,
    'sp|selectperl=s' => \$sperl,
	'h|help' => sub { print $usage; exit(1) },
	'o|out=s' => \$outdir,
	'u|uri=s' => \$uri,
	'v|verbose' => \$v,
	'no-docs' => \$nodocs,
);

ppd_to_par(
	uri => $uri,
	($v               ? (verbose      => 1            ) : ()),
	(defined($outdir) ? (out          => $outdir      ) : ()),
	($nodocs          ? (strip_docs   => 1            ) : ()),
    ($distname        ? (distname     => $distname    ) : ()),
    ($distversion     ? (distversion  => $distversion ) : ()),
    ($arch            ? (arch         => $arch        ) : ()),
    ($perl            ? (perlversion  => $perl        ) : ()),
    ($sarch           ? (selectarch   => $sarch       ) : ()),
    ($sperl           ? (selectperl   => $sperl       ) : ()),
);

__END__
:endofperl
@set "ErrorLevel=" & @goto _undefined_label_ 2>NUL || @"%COMSPEC%" /d/c @exit %ErrorLevel%
