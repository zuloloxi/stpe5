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

# Streaming zip

use strict;
use warnings;

use IO::Compress::Zip qw(zip
                         ZIP_CM_STORE
                         ZIP_CM_DEFLATE
                         ZIP_CM_BZIP2
                         ZIP_CM_LZMA );
use Getopt::Long;

my $VERSION = '1.001';

my $compression_method = ZIP_CM_DEFLATE;
my $stream = 0;
my $zipfile = '-';
my $memberName = '-' ;
my $zip64 = 0 ;

GetOptions("zip64"          => \$zip64,
           "method=s"       => \&lookupMethod,
           "stream"         => \$stream,
           "zipfile=s"      => \$zipfile,
           "member-name=s"  => \$memberName,
           'version'        => sub { print "$VERSION\n"; exit 0 },
           'help'           => \&Usage,
          )
    or Usage();

Usage()
    if @ARGV;


zip '-' => $zipfile,
           Name   => $memberName,
           Zip64  => $zip64,
           Method => $compression_method,
           Stream => $stream
    or die "Error creating zip file '$zipfile': $\n" ;

exit 0;

sub lookupMethod
{
    my $name  = shift;
    my $value = shift ;

    my %valid = ( store   => ZIP_CM_STORE,
                  deflate => ZIP_CM_DEFLATE,
                  bzip2   => ZIP_CM_BZIP2,
                  lzma    => ZIP_CM_LZMA,
                );

    my $method = $valid{ lc $value };

    Usage("Unknown method '$value'")
        if ! defined $method;

    # If LZMA was rquested, check that it is available
    if ($method == ZIP_CM_LZMA)
    {
        eval ' use IO::Compress::Adapter::Lzma';
        die "Method 'LZMA' needs IO::Compress::Adapter::Lzma\n"
            if ! defined $IO::Compress::Lzma::VERSION;
    }

    $compression_method =  $method;
}

sub Usage
{
    print <<EOM;
Usage:
  producer | streamzip [OPTIONS] | consumer
  producer | streamzip [OPTIONS] -zipfile=output.zip

Stream data from stdin, compress into a Zip container, and stream to stdout.

OPTIONS

  -zipfile=F      Write zip container to the filename 'F'
                  Outputs to stdout if zipfile not specified.
  -member-name=M  Set member name to 'M' [Default '-']
  -zip64          Create a Zip64-compliant zip file [Default: No]
                  Enable Zip64 if input is greater than 4Gig.
  -stream         Force a streamed zip file when zipfile is also enabled.
                  Only applies when 'zipfile' option is used. [Default: No]
                  Stream is always enabled when writing to stdout.
  -method=M       Compress using method 'M'.
                  Valid methods are
                    store    Store without compression
                    deflate  Use Deflate compression [Deflault]
                    bzip2    Use Bzip2 compression
                    lzma     Use LZMA compression [needs IO::Compress::Lzma]
                  Lzma needs IO::Compress::Lzma to be installed.
  -version        Display version number [$VERSION]

Copyright (c) 2019-2020 Paul Marquess. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

EOM
    exit;
}


__END__
=head1 NAME

streamzip - create a zip file from stdin

=head1 SYNOPSIS

    producer | streamzip [opts] | consumer
    producer | streamzip [opts] -zipfile=output.zip

=head1 DESCRIPTION

This program will read data from C<stdin>, compress it into a zip container
and, by default, write a I<streamed> zip file to C<stdout>. No temporary
files are created.

The zip container written to C<stdout> is, by necessity, written in
streaming format. Most programs that read Zip files can cope with a
streamed zip file, but if interoperability is important, and your workflow
allows you to write the zip file directly to disk you can create a
non-streamed zip file using the C<zipfile> option.

=head2 OPTIONS

=over 5

=item -zip64

Create a Zip64-compliant zip container. Use this option if the input is
greater than 4Gig.

Default is disabled.

=item  -zipfile=F

Write zip container to the filename C<F>.

Use the C<Stream> option to force the creation of a streamed zip file.

=item  -member-name=M

This option is used to name the "file" in the zip container.

Default is '-'.

=item  -stream

Ignored when writing to C<stdout>.

If the C<zipfile> option is specified, including this option will trigger
the creation of a streamed zip file.

Default: Always enabled when writing to C<stdout>, otherwise disabled.

=item  -method=M

Compress using method C<M>.

Valid method names are

    * store    Store without compression
    * deflate  Use Deflate compression [Deflault]
    * bzip2    Use Bzip2 compression
    * lzma     Use LZMA compression

Note that Lzma compress needs C<IO::Compress::Lzma> to be installed.

Default is C<deflate>.

=item  -version

Display version number [$VERSION]

=item -help

Display help

=back

=head2 When to use a Streamed Zip File

A Streamed Zip File is useful in situations where you cannot seek
backwards/forwards in the file.

A good examples is when you are serving dynamic content from a Web Server
straight into a socket without needing to create a temporary zip file in
the filesystsm.

Similarly if your workfow uses a Linux pipelined commands.

=head1 SUPPORT

General feedback/questions/bug reports should be sent to
L<https://github.com/pmqs/IO-Compress/issues> (preferred) or
L<https://rt.cpan.org/Public/Dist/Display.html?Name=IO-Compress>.


=head1 AUTHOR

Paul Marquess F<pmqs@cpan.org>.

=head1 COPYRIGHT

Copyright (c) 2019-2020 Paul Marquess. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
__END__
:endofperl
@set "ErrorLevel=" & @goto _undefined_label_ 2>NUL || @"%COMSPEC%" /d/c @exit %ErrorLevel%
