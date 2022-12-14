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
#!/usr/bin/perl -w
#line 16
use strict;

use XML::Twig;
use Getopt::Long;
use Pod::Usage;
use File::Temp qw{tempfile};

my $DEFAULT_SC = 'aspell -c';
my $DEFAULT_PP = 'indented';
my $DEFAULT_EXT= '.bak';

my $VERSION="0.02";

my ( $spellchecker, $ext, $attributes, $exclude_elements, 
     $include_elements, $pretty_print, $version, $help, $man);

GetOptions(  'spellchecker=s'     => \$spellchecker,
             'backup-extension=s' => \$ext,
             'attributes'         => \$attributes,
             'exclude_elements=s' => \$exclude_elements,
             'include_elements=s' => \$include_elements,
             'pretty_print:s'     => \$pretty_print,
             'version'            => \$version,
             'help'               => \$help,
             'man'                => \$man,
          ) or pod2usage(-verbose => 1, -exitval => -1);

pod2usage( -verbose => 1, -exitval => 0) if $help;
pod2usage( -verbose => 2, -exitval => 0) if $man;
if( $version) { print "$0 version $VERSION\n"; exit;}
            
# option processing
$spellchecker ||= $DEFAULT_SC;
$ext          ||= $DEFAULT_EXT;

if( $exclude_elements && $include_elements)
  { die "cannot use both --exclude-elements and --include-elements\n"; }
if( defined $pretty_print and !$pretty_print)
  { $pretty_print= $DEFAULT_PP; }

my %twig_options;

my( %include_elements);
if( $exclude_elements)
  { my @exclude_elts = split /\s+/, $exclude_elements;
    my %start_tag_handlers= map { $_ => \&exclude_elt } @exclude_elts;
    $twig_options{start_tag_handlers}= \%start_tag_handlers;
  }
if( $include_elements)
  { my @include_elts = split /\s+/, $include_elements;
    my %start_tag_handlers= map { $_ => \&include_elt } @include_elts;
    $twig_options{start_tag_handlers}= \%start_tag_handlers;
  }

$twig_options{pretty_print}= $pretty_print if( $pretty_print);

foreach my $file (@ARGV)
  { 
    my $id=0;
    my $id2elt={};           # id => element

    my( $tmp_fh, $tmp_file) = tempfile( "xml_spellcheck_XXXX", 
                                        SUFFIX => '.txt'
                                      );
    my $t= XML::Twig->new( keep_encoding =>1, %twig_options,);
    $t->parsefile( $file);

    foreach my $elt ($t->descendants( '#TEXT'))
      {
        if(    (!$include_elements and !$exclude_elements)
            or ($include_elements and  $elt->inherit_att( '#include'))
            or ($exclude_elements and !$elt->inherit_att( '#exclude'))
          )
          { $id++;
            process_text( $t, $elt, $id, $id2elt, $tmp_fh)
          }
      }
    close $tmp_fh;

    system( "$spellchecker $tmp_file") ==0
      or die "$spellchecker $tmp_file failed: $?";

   
    open( $tmp_fh, "<$tmp_file") or die "cannot open temp file $tmp_file: $!";
    while( <$tmp_fh>)
      { chomp;
        my( $id, $text)= split /:/, $_, 2;
        my $wrap= $id2elt->{$id};
        $text=~ s{<\\n>}{\n}g;
        my $text_elt= $wrap->first_child or die "internal error 100\n";
        if( $text_elt->gi eq '#PCDATA')
          { $text_elt->set_pcdata( $text); }
        elsif( $text_elt->gi eq '#CDATA')
          { $text_elt->set_cdata( $text); }
        else 
          { die "internal error 101\n"; }
        $wrap->erase;
      }
    close $tmp_fh;

    rename( $file, "$file$ext") or die "cannot save backup file $file$ext: $!";
    open( FILE, ">$file")       or die "cannot save spell checked file $file: $!";
    $t->print( \*FILE);
    close FILE;
  }     


sub include_elt
  { $_->set_att( '#include' => 1) ; }

sub exclude_elt
  { $_->set_att( '#exclude' => 1) ; }

sub process_text
  { my( $t, $elt, $id, $id2elt, $tmp_fh)= @_;
    my $wrap= $elt->wrap_in( '#SC');
    #$wrap->set_att( '#ID' => $id);
    $id2elt->{$id}= $wrap;
    my $text= $elt->text;
    $text=~ s{\n}{<\\n>}g;
    print $tmp_fh "$id:$text\n";
  }

__END__

=head1 NAME

xml_spellcheck - spellcheck XML files

=head1 SYNOPSIS

  xml_spellcheck [options] <files>

=head1 DESCRIPTION

xml_spellcheck lets you spell check the content of an XML file.
It extracts the text (the content of elements and optionally of
attributes), call a spell checker on it and then recreates the
XML document.

=head1 OPTIONS

Note that all options can be abbreviated to the first letter

=over 4

=item --conf <configuration_file>

Gets the options from a configuration file. NOT IMPLEMENTED YET.

=item --spellchecker <spellchecker>

The command to use for spell checking, including any option

By default C<aspell -c> is used

=item --backup-extension <extension>

By default the original file is saved with a C<.bak> extension. This option
changes the extension

=item --attributes 

Spell check attribute content. By default attribute values are NOT
spell checked. NOT YET IMPLEMENTED

=item --exclude_elements <list_of_excluded_elements>

A list of elements that should not be spell checked

=item --include_elements <list_of_included_elements>

A list of elements that should be spell checked (by default all elements
are spell checked). 

C<--exclude_elements> and C<--include_elements> are mutually exclusive

=item --pretty_print <optional_pretty_print_style>

A pretty print style for the document, as defined in XML::Twig. If
the option is provided without a value then the C<indented> style is
used

=item --version

Dislay the tool version and exit

=item --help

Display help message and exit

=item --man

Display longer help message and exit

=back

=head1 EXAMPLES

=head1 BUGS

=head1 TODO

=over 4

=item --conf option

=item --attribute option

=back

=head1 PRE-REQUISITE

XML::Twig, Getopt::Long, Pod::Usage, File::Temp
XML::Twig requires XML::Parser.

=head1 SEE ALSO

XML::Twig

=head1 COPYRIGHT AND DISCLAIMER

This program is Copyright 2003 by Michel Rodriguez

This program is free software; you can redistribute it and/or modify
it under the terms of the Perl Artistic License or the GNU General 
Public License as published by the Free Software Foundation either
version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MER-
CHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

If you do not have a copy of the GNU General Public License write to
the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139,
USA.

=head1 AUTHOR 

Michel Rodriguez <mirod@xmltwig.com>

xml_spellcheck is available at http://www.xmltwig.com/xmltwig/

__END__
:endofperl
@set "ErrorLevel=" & @goto _undefined_label_ 2>NUL || @"%COMSPEC%" /d/c @exit %ErrorLevel%
