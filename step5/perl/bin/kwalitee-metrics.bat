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

# ABSTRACT: list details of all kwalitee metrics installed on the system
# PODNAME: kwalitee-metrics
use strict;
use warnings;
use Module::CPANTS::Analyse 0.91;

my $verbose = @ARGV && ($ARGV[0] eq '--verbose' || $ARGV[0] eq '-v');

my $analyzer = Module::CPANTS::Analyse->new({
    distdir => '.',
    dist => '.',
    opts => { no_capture => 1 },
});

# TODO: MCA needs an API for doing this iteration.

for my $generator (@{ $analyzer->mck->generators })
{
    print $generator, ' ', $generator->VERSION, "\n";

    for my $indicator (sort { $a->{name} cmp $b->{name} } @{ $generator->kwalitee_indicators })
    {
        print "  $indicator->{name}";

        my @flags = grep { exists $indicator->{$_} }
            qw(is_extra is_experimental needs_db);
        print ' (', join(', ', @flags), ')' if @flags;
        print "\n";

        print "    error: $indicator->{error}\n" if $verbose;
        print "    remedy: $indicator->{remedy}\n" if $verbose;
    }
}
continue { print "\n"; }

__END__

=pod

=encoding UTF-8

=head1 NAME

kwalitee-metrics - list details of all kwalitee metrics installed on the system

=head1 VERSION

version 1.28

=head1 DESCRIPTION

Dumps all of the kwalitee metrics, along with their source class, currently
installed on the system.

=for stopwords programmatically

If C<--verbose> or C<-v> is passed as an argument, the 'error' and 'remedy'
strings for the metric are included, as a sort of documentation (the only kind
programmatically available).

=head1 SEE ALSO

=over 4

=item *

L<Test::Kwalitee>

=item *

L<Module::CPANTS::Analyse>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Kwalitee>
(or L<bug-Test-Kwalitee@rt.cpan.org|mailto:bug-Test-Kwalitee@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/perl-qa.html>.

There is also an irc channel available for users of this distribution, at
L<C<#perl> on C<irc.perl.org>|irc://irc.perl.org/#perl-qa>.

=head1 AUTHORS

=over 4

=item *

chromatic <chromatic@wgz.org>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by chromatic.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
__END__
:endofperl
@set "ErrorLevel=" & @goto _undefined_label_ 2>NUL || @"%COMSPEC%" /d/c @exit %ErrorLevel%
