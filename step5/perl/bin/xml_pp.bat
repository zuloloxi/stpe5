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
# $Id: /xmltwig/trunk/tools/xml_pp/xml_pp 32 2008-01-18T13:11:52.128782Z mrodrigu  $
use strict;

use XML::Twig;
use File::Temp qw/tempfile/;
use File::Basename qw/dirname/;

my @styles= XML::Twig->_pretty_print_styles; # from XML::Twig
my $styles= join '|', @styles;               # for usage
my %styles= map { $_ => 1} @styles;          # to check option

my $DEFAULT_STYLE= 'indented';

my $USAGE= "usage: $0 [-v] [-i<extension>] [-s ($styles)] [-p <tag(s)>] [-e <encoding>] [-l] [-f <file>] [<files>]";

# because of the -i.bak option I don't think I can use one of the core
# option processing modules, so it's custom handling and no clusterization :--(


my %opt= process_options(); # changes @ARGV

my @twig_options=( pretty_print  => $opt{style},
                   error_context => 1,
                 );
if( $opt{preserve_space_in})
  { push @twig_options, keep_spaces_in => $opt{preserve_space_in};}

if( $opt{encoding})
  { push @twig_options, output_encoding  => $opt{encoding};
  }
else
  { push @twig_options, keep_encoding => 1; }

# in normal (ie not -l) mode tags are output as soon as possible
push @twig_options, twig_handlers => { _all_ => sub { $_[0]->flush } }
  unless( $opt{load});

if( @ARGV)
  { foreach my $file (@ARGV)
      { print STDERR "$file\n" if( $opt{verbose});

        my $t= XML::Twig->new( @twig_options);

        my $tempfile;
        if( $opt{in_place})
          { (undef, $tempfile)= tempfile( DIR => dirname( $file)) or die "cannot create tempfile for $file: $!\n" ;
            open( PP_OUTPUT, ">$tempfile") or die "cannot create tempfile $tempfile: $!";
            select PP_OUTPUT;
          }
        $t= $t->safe_parsefile( $file);

        if( $t)
          { if( $opt{load}) { $t->print; }

            select STDOUT;

            if( $opt{in_place})
              { close PP_OUTPUT;
                my $mode= mode( $file);
                if( $opt{backup})  
                  { my $backup= backup( $file, $opt{backup});
                    rename( $file, $backup) or die "cannot create backup file $backup: $!"; 
                  }
                rename( $tempfile, $file) or die "cannot overwrite file $file: $!";
                if( $mode ne mode( $file)) { chmod $mode, $file or die "cannot set $file mode to $mode: $!"; }
              }

          }
        else
          { if( defined $tempfile)
              { unlink $tempfile or die "cannot unlink temp file $tempfile: $!"; }
            die $@;
          }
      }
  }
else
  { my $t= XML::Twig->new( @twig_options);
    $t->parse( \*STDIN); 
    if( $opt{load}) { $t->print; }
  }

 
sub mode
  { my( $file)= @_;
    return (stat($file))[2];
  }
 
sub process_options
  { my %opt; 
    while( @ARGV && ($ARGV[0]=~ m{^-}) )
      { my $opt= shift @ARGV;
        if(    ($opt eq '-v') || ($opt eq '--verbose') ) 
          { die $USAGE if( $opt{verbose});
            $opt{verbose}= 1;
          }
        elsif( ($opt eq '-s') || ($opt eq '--style') )  
          { die $USAGE if( $opt{style});
            $opt{style}= shift @ARGV;
            die $USAGE unless( $styles{$opt{style}});
          }
        elsif( ($opt=~ m{^-i(.*)$}) || ($opt=~ m{^--in_place(.*)$}) )
          { die $USAGE if( $opt{in_place});
            $opt{in_place}= 1;
            $opt{backup}= $1 ||'';
          }
        elsif( ($opt eq '-p') || ($opt eq '--preserve') )  
          { my $tags= shift @ARGV;
            my @tags= split /\s+/, $tags;
            $opt{preserve_space_in} ||= [];
            push @{$opt{preserve_space_in}}, @tags;
          }
        elsif( ($opt eq '-e') || ($opt eq '--encoding') ) 
          { die $USAGE if( $opt{encoding});
            $opt{encoding}= shift @ARGV;
          }
        elsif( ($opt eq '-l') || ($opt eq '--load'))
          { die $USAGE if( $opt{load});
            $opt{load}=1;
          }
       elsif( ($opt eq '-f') || ($opt eq '--files') ) 
         { my $file= shift @ARGV;
           push @ARGV, files_from( $file);
          }
        elsif( ($opt eq '-h') || ($opt eq '--help'))  
         { system "pod2text", $0; exit; }
        elsif( $opt eq '--')  
         { last;       }
        else
         { die $USAGE; }
      }

    $opt{style} ||= $DEFAULT_STYLE;

    return %opt;
  }

# get the list of files (one per line) from a file
sub files_from
  { my $file= shift;
    open( FILES, "<$file") or die "cannot open file $file: $!";
    my @files;
    while( <FILES>) { chomp; push @files, $_; }
    close FILES;
    return @files;
  }

sub backup
  { my( $file, $extension)= @_;
    my $backup;
    if( $extension=~ m{\*})
      { ($backup= $extension)=~ s{\*}{$file}g; }
    else
      { $backup= $file.$extension; }
    return $backup;
  }
  
__END__

=head1 NAME

xml_pp - xml pretty-printer

=head1 SYNOPSYS

xml_pp [options] [<files>]

=head1 DESCRIPTION

XML pretty printer using XML::Twig

=head1 OPTIONS

=over 4

=item -i[<extension>]

edits the file(s) in place, if an extension is provided (no space between 
C<-i> and the extension) then the original file is backed-up with that extension

The rules for the extension are the same as Perl's (see perldoc perlrun): if
the extension includes no "*" then it is appended to the original file name,
If the extension does contain one or more "*" characters, then each "*" is 
replaced with the current filename.

=item -s <style>

the style to use for pretty printing: none, nsgmls, nice, indented, record, or
record_c (see XML::Twig docs for the exact description of those styles), 
'indented' by default

=item -p <tag(s)> 

preserves white spaces in tags. You can use several C<-p> options or quote the 
tags if you need more than one

=item -e <encoding>

use XML::Twig output_encoding (based on Text::Iconv or Unicode::Map8 and 
Unicode::String) to set the output encoding. By default the original encoding
is preserved. 

If this option is used the XML declaration is updated (and created if there was
none).

Make sure that the encoding is supported by the parser you use if you want to
be able to process the pretty_printed file (XML::Parser does not support 
'latin1' for example, you have to use 'iso-8859-1')

=item -l

loads the documents in memory instead of outputting them as they are being
parsed.

This prevents a bug (see L<BUGS|bugs>) but uses more memory

=item -f <file>

read the list of files to process from <file>, one per line

=item -v 

verbose (list the current file being processed)

=item --

stop argument processing (to process files that start with -)

=item -h

display help

=back

=head1 EXAMPLES

  xml_pp foo.xml > foo_pp.xml           # pretty print foo.xml 
  xml_pp < foo.xml > foo_pp.xml         # pretty print from standard input

  xml_pp -v -i.bak *.xml                # pretty print .xml files, with backups
  xml_pp -v -i'orig_*' *.xml            # backups are named orig_<filename>

  xml_pp -i -p pre foo.xhtml            # preserve spaces in pre tags
  
  xml_pp -i.bak -p 'pre code' foo.xml   # preserve spaces in pre and code tags
  xml_pp -i.bak -p pre -p code foo.xml  # same

  xml_pp -i -s record mydb_export.xml   # pretty print using the record style

  xml_pp -e utf8 -i foo.xml             # output will be in utf8
  xml_pp -e iso-8859-1 -i foo.xml       # output will be in iso-8859-1

  xml_pp -v -i.bak -f lof               # pretty print in place files from lof
  
  xml_pp -- -i.xml                      # pretty print the -i.xml file

  xml_pp -l foo.xml                     # loads the entire file in memory 
                                        # before pretty printing it

  xml_pp -h                             # display help

=head1 BUGS

Elements with mixed content that start with an embedded element get an extra \n 

  <elt><b>b</b>toto<b>bold</b></elt>

will be output as 

  <elt>
    <b>b</b>toto<b>bold</b></elt>

Using the C<-l> option solves this bug (but uses more memory)

=head1 TODO

update XML::Twig to use Encode with perl 5.8.0

=head1 AUTHOR

Michel Rodriguez <mirod@xmltwig.com>
__END__
:endofperl
@set "ErrorLevel=" & @goto _undefined_label_ 2>NUL || @"%COMSPEC%" /d/c @exit %ErrorLevel%
