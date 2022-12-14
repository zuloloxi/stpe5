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
# $Id: /xmltwig/trunk/tools/xml_split/xml_split 17 2007-06-04T11:57:10.366292Z mrodrigu  $
use strict;

use XML::Twig;
use FindBin qw( $RealBin $RealScript);
use Getopt::Std;

import xml_split::state::parser;
import xml_split::state::twig;

undef $Getopt::Std::STANDARD_HELP_VERSION;
$Getopt::Std::STANDARD_HELP_VERSION=1; # to stop processing after --help or --version

use vars qw( $VERSION $USAGE);

$VERSION= "0.06";
$USAGE= "xml_split [-l <level> [-s <size> | -g <nb_grouped>] | -c <cond>] [-b <base>] [-n <nb>] [-e <ext>] [-p <plugin>] [-I <plugin_dir>] [-i] [-d] [-v] [-h] [-m] [-V] <files>\n";

{ # main block

my $opt={};
getopts('l:c:b:g:n:e:p:is:dvhmV', $opt);

# defaults
$opt->{n} ||= 2; # number of digits used for creating parts
$opt->{I} ||= ($ENV{HOME} || '') . "/.xml_split";

if( $opt->{h}) { die $USAGE, "\n";            }
if( $opt->{m}) { exec "pod2text $RealBin/$RealScript"; }
if( $opt->{V}) { print "xml_split version $VERSION\n"; exit; }

my %factor=( ' ' => 1, K => 1000, M => 1_000_000, G => 1_000_000_000);
if( $opt->{s}) { if( $opt->{c}) { die "cannot use -c and -s at the same time\n"; }

                 if( $opt->{s}=~ m{^\s*(\d+)\s*(G[bo]?|M[bo]?|K[bo]?\s*)?$}i)
                   { my( $size, $unit)= ($1, uc substr( $2 || ' ', 0, 1));
                     $opt->{s}= $size * $factor{$unit};
                   }
                 else
                   { die "invalid size (should be in Kb, Mb or Gb): '$opt->{s}'\n"; }
               }

if( $opt->{g}) { die "cannot use -g and -s at the same time\n" if( $opt->{s});
                 die "cannot use -g and -c at the same time\n" if( $opt->{c});
                 $opt->{l} ||= 1;
               }
elsif( $opt->{c}) { die "cannot use -l and -c at the same time\n" if( $opt->{l}); }
else           { $opt->{l} ||= 1; $opt->{c}= "level( $opt->{l})"; }


my $options= { cond     => $opt->{c}, 
               base     => $opt->{b}, nb_digits => $opt->{n}, ext => $opt->{e},
               plugin   => $opt->{p},
               no_pi    => $opt->{d},
               verbose  => $opt->{v}, 
               xinclude => $opt->{i} ? 1 : 0,
             };


my $state;
if( my $plugin= $opt->{p}) 
  { if( $plugin!~ m{^[\w:.-]+$}) { die "wrong plugin name '$plugin' (only word characters are allowed in plugin names)\n"; }
    push @INC, $opt->{I};
    eval { require $plugin };
    if( $@) { die "cannot find plugin '$plugin': $!"; }
    import $plugin;
    $state= $plugin->new( $options);
  }
  

if( $opt->{s})
  { $state||= xml_split::state::parser->new( $options);
    $state->{level} = $opt->{l};
    $state->{size}  = $opt->{s};
    $state->{current_size}=0;
    $state->{handlers}= { Start => \&parser_start_tag_size, End => \&parser_end_tag_size , Default => \&parser_default_size}; 
    warn "using XML::Parser\n" if( $opt->{v});
    split_with_parser( $state, @ARGV);
  }
elsif( $opt->{g})
  { $state||= xml_split::state::parser->new( $options);
    $state->{level}= $opt->{l};
    $state->{group}= $opt->{g};
    $state->{handlers}= { Start => \&parser_start_tag_grouped, End => \&parser_end_tag_grouped , Default => \&parser_default_grouped}; 
    warn "using XML::Parser\n" if( $opt->{v});
    split_with_parser( $state, @ARGV);
  }
elsif( $opt->{l})
  { $state||= xml_split::state::parser->new( $options);
    $state->{level}= $opt->{l};
    $state->{handlers}= { Start => \&parser_start_tag_level, End => \&parser_end_tag_level , Default => \&parser_default_level}; 
    warn "using XML::Parser\n" if( $opt->{v});
    split_with_parser( $state, @ARGV);
  }
else
  { $state||= xml_split::state::twig->new( $options);
    split_with_twig( $state, @ARGV);
  }

exit;
}    

sub split_with_twig
  { my( $state, @files)= @_;
    if( !@files)
      { $state->{base} ||= 'out';
        $state->{ext}  ||= '.xml';
        my $twig_options= twig_options( $state);
        my $t= XML::Twig->new( %$twig_options, $state);
        $state->{twig}= $t;
        $t->parse( \*STDIN);
        end_file( $t, $state);
      }
    else
      { foreach my $file (@files)
          { 
            unless( $state->{base}) { $state->{seq_nb}=0; }
            my( $base, $ext)= ($file=~ m{^(.*?)(\.\w+)?$});
            $state->{base} ||= $base;
            $state->{ext}  ||= $ext || '.xml';
            my $twig_options= twig_options( $state);
            my $t= XML::Twig->new( %$twig_options);
            $state->{twig}= $t;
            $t->parsefile( $file);
            end_file( $t, $state);
          }
      }
  }

sub split_with_parser
  { my( $state, @files)= @_;
    if( !@files)
      { $state->{base} ||= 'out';
        $state->{ext}  ||= '.xml';
        my $parser_options= parser_options( $state);
        my $p= XML::Parser->new( %$parser_options);
        $state->{parser}= $p;
        $p->parse( \*STDIN);
      }
    else
      { foreach my $file (@files)
          { 
            unless( $state->{base}) { $state->{seq_nb}=0; }
            my( $base, $ext)= ($file=~ m{^(.*?)(\.\w+)?$});
            $state->{base} ||= $base;
            $state->{ext}  ||= $ext || '.xml';
            my $parser_options= parser_options( $state);
            my $p= XML::Parser->new( %$parser_options);
            $state->{parser}= $p;
            $p->parsefile( $file);
          }
      }
  }
  
sub parser_options
  { my( $state)= @_;
    # prepare output to the main document
    unless( $state->{no_pi})
      { my $file_name= $state->main_file_name(); # main file name
        warn "generating main file $file_name\n" if( $state->{verbose});
        open( my $out, '>', $file_name) or die "cannot create main file '$file_name': $!";
        $state->{main_fh}= $out;
        $state->{current_fh}= $out;
      }
   my $handlers= { Start   => sub { $state->{handlers}->{Start}->(   $state, shift( @_)); },
                   End     => sub { $state->{handlers}->{End}->(     $state, shift( @_)); },
                   Default => sub { $state->{handlers}->{Default}->( $state, shift( @_)); },
                   XMLDecl => sub { parser_declaration( $state, @_);                      },
                 };
    
    return { Handlers => $handlers };
  }

###################################################################################
#                                                                                 #
#  handlers for the -l option                                                     #
#                                                                                 #
###################################################################################

sub parser_start_tag_level
  { my( $state, $p)= @_;

    if( $p->depth == $state->{level})
      { $state->{seq_nb}++;
        my $file_name= $state->file_name;
        # prepare chunk file
        warn "generating $file_name\n" if( $state->{verbose});
        open( my $out, '>', $file_name) or die "cannot create output file '$file_name': $!";
        $state->{current_fh}= $out;
        if( $state->{xml_declaration}) { print {$state->{current_fh}} $state->{xml_declaration}, "\n"; }
        # output pi
        unless( $state->{no_pi})
          { print {$state->{main_fh}} $state->include( $file_name) ; }
      }
    print {$state->{current_fh}} $p->original_string if( $state->{current_fh});
  }
  
sub parser_end_tag_level
  { my( $state, $p)= @_;
    print {$state->{current_fh}} $p->original_string if( $state->{current_fh});
    if( $p->depth == $state->{level})
      { unless( $state->{current_fh} == $state->{main_fh})
          { close $state->{current_fh};
            $state->{current_fh}= $state->{main_fh};
          }
      }
  }

sub parser_default_level
  { my( $state, $p)= @_;
    print {$state->{current_fh}} $p->original_string if( $state->{current_fh});
  }


###################################################################################
#                                                                                 #
#  handlers for the -s option                                                     #
#                                                                                 #
###################################################################################

sub parser_start_tag_size
  { my( $state, $p)= @_;
    if( $p->depth == $state->{level} && !$state->{current_size})
      { 
        $state->{seq_nb}++;
        my $file_name= $state->file_name;
        # prepare chunk file
        warn "generating $file_name\n" if( $state->{verbose});
        open( my $out, '>', $file_name) or die "cannot create output file '$file_name': $!";
        $state->{current_fh}= $out;
        print {$state->{current_fh}} qq{$state->{xml_declaration}\n} if $state->{xml_declaration};
        print {$state->{current_fh}} qq{<xml_split:root xmlns:xml_split="http://xmltwig.com/xml_split">\n};
        # output pi
        unless( $state->{no_pi})
          { print {$state->{main_fh}} $state->include( $file_name) ; }
        $state->{store_size}=1;
      }
    my $original_string= $p->original_string;
    $state->{current_size} += length( $original_string) if( $state->{store_size});
    print {$state->{current_fh}} $original_string if( $state->{current_fh});
  }
  
sub parser_end_tag_size
  { my( $state, $p)= @_;
    my $original_string= $p->original_string;   
    $state->{current_size} += length( $original_string) if( $state->{store_size});
    if( $p->depth == $state->{level} && $state->{current_size} > $state->{size})
      { print {$state->{current_fh}} $original_string if( $state->{current_fh});
        end_file_with_size( $state); 
      }
    else
      { if($p->depth < $state->{level}) { end_file_with_size( $state); }
        print {$state->{current_fh}} $p->original_string if( $state->{current_fh});
      }
  }

sub end_file_with_size
  { my( $state)= @_;
    unless( $state->{current_fh} == $state->{main_fh})
      { print {$state->{current_fh}} qq{\n</xml_split:root>\n};
        close $state->{current_fh};
        $state->{current_size}=0; 
        $state->{store_size}=0;
        $state->{current_fh}= $state->{main_fh};
      }
  }

sub parser_default_size
  { my( $state, $p)= @_;
    my $string= $p->original_string;
    if( $state->{store_size})
      { $state->{current_size} += length( $string);
        if( $p->depth < $state->{level}) { end_file_with_size( $state); }
      }
    print {$state->{current_fh}} $string if( $state->{current_fh});
  }

###################################################################################
#                                                                                 #
#  handlers for the -g option                                                     #
#                                                                                 #
###################################################################################

sub parser_start_tag_grouped
  { my( $state, $p)= @_;
    if( $p->depth == $state->{level})
      { if( !$state->{current_nb})
          { $state->{seq_nb}++;
            my $file_name= $state->file_name;
            # prepare chunk file
            warn "generating $file_name\n" if( $state->{verbose});
            open( my $out, '>', $file_name) or die "cannot create output file '$file_name': $!";
            $state->{current_fh}= $out;
            print {$state->{current_fh}} join( "\n", grep { $_ } ( $state->{xml_declaration}, 
                                                                   qq{<xml_split:root xmlns:xml_split="http://xmltwig.com/xml_split">\n  }
                                                                 )
                                             );
            # output pi
            unless( $state->{no_pi})
              { print {$state->{main_fh}} $state->include( $file_name) ; }
          }
      }
    print {$state->{current_fh}} $p->original_string if( $state->{current_fh});
  }
  
sub parser_end_tag_grouped
  { my( $state, $p)= @_;
    if( $p->depth == $state->{level})
      { print {$state->{current_fh}} $p->original_string if( $state->{current_fh});
        $state->{current_nb}++;
        if( $state->{current_nb} == $state->{group}) { end_file_grouped( $state); } 
      }
    else
      { if($p->depth < $state->{level}) { end_file_grouped( $state, { no_nl => 1 }); } 
        print {$state->{current_fh}} $p->original_string if( $state->{current_fh});
      }
  }

sub end_file_grouped
  { my( $state, $options)= @_;
    print {$state->{current_fh}} qq{\n} unless( $options->{no_nl});
    unless( $state->{current_fh} == $state->{main_fh})
      { print {$state->{current_fh}} qq{</xml_split:root>\n};
        close $state->{current_fh};
        $state->{current_nb}=0; 
        $state->{current_fh}= $state->{main_fh};
      }
  }

sub parser_default_grouped
  { my( $state, $p)= @_;
    print {$state->{current_fh}} $p->original_string if( $state->{current_fh});
  }

sub char_parser
  { my( $state, $p)=( shift, shift);
    print {$state->{current_fh}} $_[0] if( $state->{current_fh});
  }

sub parser_declaration
  { my( $state, $p, $version, $encoding, $standalone)= @_;
    $state->{xml_declaration}=  $p->recognized_string || ''; 
    print {$state->{main_fh}} $state->{xml_declaration}; 
    # avoid calling original_string if not needed
    #if( !$state->{xml_declaration} || $state->{xml_declaration}=~ m{encoding\s*=\s*["']utf-?8["']}i)
    #  { $state->{utf8_encoded}=1;
    #    $p->setHandlers( Char => \&char_parser);
    #  }
  } 


sub twig_options
  { my( $state)= @_;

    # base options, ensures maximum fidelity to the original document
    my $twig_options= { keep_encoding => 1, keep_spaces => 1 };

    # prepare output to the main document
    unless( $state->{no_pi})
      { my $file_name= $state->main_file_name(); # main file name
        warn "generating main file $file_name\n" if( $state->{verbose});
        open( my $out, '>', $file_name) or die "cannot create main file '$file_name': $!";
        $state->{out}= $out;
        $twig_options->{twig_print_outside_roots}= $out;
        $twig_options->{start_tag_handlers}= { $state->{cond} => sub { $_->set_att( '#in_fragment' => 1); }  };
      }
    
    $twig_options->{twig_roots}= { $state->{cond} => sub { dump_elt( @_, $state); } };
    return $twig_options;
  }

sub dump_elt
  { my( $t, $elt, $state)= @_;
    $state->{seq_nb}++;
    $state->{elt}= $elt;

    my $file_name= $state->file_name;
    warn "generating $file_name\n" if( $state->{verbose});

    my $fragment= XML::Twig->new();
    $fragment->{twig_xmldecl} = $t->{twig_xmldecl};
    $fragment->{twig_doctype} = $t->{twig_doctype};
    $fragment->{twig_dtd}     = $t->{twig_dtd};
   
    if( !$state->{no_pis})
      { # if we are still within a fragment, just replace the element by the PI
        # otherwise print it to the main document
        my $include= $state->include( $file_name);

        $elt->del_att( '#in_fragment');
        
        if( $elt->inherited_att( '#in_fragment'))
          { $elt->parent( '*[@#in_fragment="1"]')->set_att( '#has_subdocs' => 1);
            $include->replace( $elt);
          }
        else
          { $elt->cut;
            $include->print( $state->{out});
          }
      }
    else
      { $elt->cut; }
      
    $fragment->set_root( $elt);
    open( my $out, '>', $file_name) or die "cannot create output file '$file_name': $!";
    #if( $state->{xml_declaration}) { warn "c1"; print {$out} $state->{xml_declaration}, "\n"; }
    #if( $fragment->{xml_decl}) { warn "c2"; print {$out} $fragment->xml_decl, "\n"; }
    $fragment->set_keep_encoding( 1);
    $fragment->print( $out);
    close $out;
  }
  
sub end_file
  { my( $t, $state)= @_;
    unless( $state->{no_pi})
      { close $state->{out}; }
  }  

 
# for Getop::Std
sub HELP_MESSAGE    { return $USAGE;   }
sub VERSION_MESSAGE { return $VERSION; } 

package xml_split::state;

sub new 
  { my( $ref, $options)= @_;
    my $state= bless $options, $ref;
    $state->{seq_nb}=0;
    return $state;
  }

sub file_name
  { my( $state)= @_;
    my $nb= sprintf( "%0$state->{nb_digits}d", $state->{seq_nb});
    my $file_name= "$state->{base}-$nb$state->{ext}";
    $file_name =~ s{\\}{/}g; 
    return $file_name;
  }

sub main_file_name
  { my( $state)= @_;
    my $nb= sprintf( "%0$state->{nb_digits}d", 0);
    my $file_name= "$state->{base}-$nb$state->{ext}";
    return $file_name;
  }
1;

###################################################################################
#                                                                                 #
#  state when using XML::Parser                                                   #
#                                                                                 #
###################################################################################

package xml_split::state::parser;
import xml_split::state;
use base 'xml_split::state';

sub include
  { my( $state, $file_name)= @_;
    if( $state->{xinclude})
      { return qq{<xi:include href="$file_name" />}; }
    else
      { return qq{<?merge subdocs = 0 :$file_name?>}; }
  }
1;

###################################################################################
#                                                                                 #
#  state when using XML::Twig                                                     #
#                                                                                 #
###################################################################################

package xml_split::state::twig;
import xml_split::state;
use base 'xml_split::state';

sub include
  { my( $state, $file_name)= @_;
    my $include;
    my $subdocs= $state->{elt}->att( '#has_subdocs') || 0;
    if( $state->{xinclude})
      { $include= XML::Twig::Elt->new( 'xi:include', { href => $file_name });
        if( $subdocs) { $include->set_att( subdocs => 1); }
      }
    else
      { 
        $include=  XML::Twig::Elt->new( '#PI')
                                 ->set_pi( merge => " subdocs = $subdocs :$file_name");
      }
    return $include;
  }

1;

package main;

__END__

=head1 NAME

  xml_split - cut a big XML file into smaller chunks

=head1 DESCRIPTION

C<xml_split> takes a (presumably big) XML file and split it in several smaller
files. The memory used is the memory needed for the biggest chunk (ie memory
is reused for each new chunk).

It can split at a given level in the tree (the default, splits children of the
root), or on a condition (using the subset
of XPath understood by XML::Twig, so C<section> or C</doc/section>).

Each generated file is replaced by a processing instruction that will allow 
C<xml_merge> to rebuild the original document. The processing instruction
format is C<< <?merge subdocs=[01] :<filename> ?> >>

File names are <file>-<nb>.xml, with <file>-00.xml holding the main document. 

=head1 OPTIONS

=over 4

=item -l <level>    

level to cut at: 1 generates a file for each child of the root, 2 for each grand
child

defaults to 1

=item -c <condition>

generate a file for each element that passes the condition

xml_split -c <section> will put each C<section> element in its own file (nested
sections are handled too)

Note that at the moment this option is a lot slower than using C<-l>

=item -s <size>

generates files of (approximately) <size>. The content of each file is
enclosed in a new element (C<xml_split::root>), so it's well-formed XML.
The size can be given in bytes, Kb, Mb or Gb. 

=item -g <nb>

groups <nb> elements in a single file. The content of each file is
enclosed in a new element (C<xml_split::root>), so it's well-formed XML.

=item -b <name>

base name for the output, files will be named <base>-<nb><.ext>

<nb> is a sequence number, see below C<--nb_digits>
<ext> is an extension, see below C<--extension>

defaults to the original file name (if available) or C<out> (if input comes 
from the standard input)

=item -n <nb>

number of digits in the sequence number for each file

if more digits than <nb> are needed, then they are used: if C<--nb_digits 2> is used
and 112 files are generated they will be named C<< <file>-01.xml >> to C<< <file>-112.xml >>

defaults to 2

=item -e <ext>

extension to use for generated files

defaults to the original file extension or C<.xml>

=item -i

use XInclude elements instead of Processing Instructions to mark where
sub files need to be included

=item -v

verbose output

Note that this option can slow down processing considerably (by an order of
magnitude) when generating lots of small documents

=item -V

outputs version and exit

=item -h

short help

=item -m

man (requires pod2text to be in the path)


=back

=head1 EXAMPLES

  xml_split foo.xml             # split at level 1
  xml_split -l 2 foo.xml        # split at level 2
  xml_split -c section foo.xml  # a file is generated for each section element
                                # nested sections are split properly

=head1 SEE ALSO

XML::Twig, xml_merge

=head1 TODO

=over 4

=item optimize the code

any idea welcome! I have already implemented most of what I thought would 
improve performances.

=item provide other methods that PIs to keep merge information

XInclude is a good candidate (alpha support added in 0.04).

using entities, which would seem the natural way to do it,
doesn't work, as they make it impossible to have both the main document
and the sub docs to be well-formed if the sub docs include sub-sub docs (you 
can't have entity declarations in an entity)

=back

=head1 AUTHOR

Michel Rodriguez <mirod@cpan.org>

=head1 LICENSE

This tool is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

__END__
:endofperl
@set "ErrorLevel=" & @goto _undefined_label_ 2>NUL || @"%COMSPEC%" /d/c @exit %ErrorLevel%
