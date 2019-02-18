package Perl::ScriptRunner;

use 5.016001;
use strict;
use warnings;

use Carp;
use IO::Handle;
use IO::Select;
use POSIX ":sys_wait_h";
use Time::HiRes qw/ gettimeofday tv_interval /;

our $VERSION = "0.01";


sub new {
    my ( $class, $args ) = @_;

    my $self = bless {}, $class;

    $self->{timeout} = ( defined $args->{timeout} ) ? $args->{timeout} : 60;
    $self->{combine_out} = ( defined $args->{combine_out} ) ?  $args->{combine_out} : 0;

    return $self;
}

sub timeout {
    my ($self, $val ) = @_;

    if ( defined $val ) {
        my $prev = $self->{'timeout'};
        $self->{'timeout'} = $val;
        return $prev;
    }
    else {
        return $self->{'timeout'};
    }
}

sub run {
    my ( $self, $script, @args ) = @_;

    if ( !defined $script ) {
        croak("script required");
    }

    my $stdout_rdr = IO::Handle->new();
    my $stdout_wtr = IO::Handle->new();

    my $stderr_rdr = IO::Handle->new();
    my $stderr_wtr = IO::Handle->new();

    if ( ! pipe $stdout_rdr, $stdout_wtr ) {
        croak("Could not create stdout pipe: $!");
    }

    if ( ! pipe $stderr_rdr, $stderr_wtr ) {
        croak("Could not create stderr pipe: $!");
    }

    $stdout_wtr->autoflush(1);
    $stderr_wtr->autoflush(1);

    my $rc;
    local $SIG{CHLD} = sub {
        while ( ( my $child = waitpid( -1, &POSIX::WNOHANG ) ) > 0 ) {
            $rc = $?;
        }
    };

    my $pid = fork();
    if ( $pid > 0 ) {
        # parent does not write anything to child
        $stdout_wtr->close();
        $stderr_wtr->close();

        my ( $out, $err );

        my $len = 4096;
        my $max_time = $self->{timeout};
        my $t_inc = 0.01;
        my $t = 0;

        my $sel = IO::Select->new();
        $sel->add($stdout_rdr->fileno());
        $sel->add($stderr_rdr->fileno());

        my $t0 = [gettimeofday];
        while (1) {
            my @ready = $sel->can_read($t_inc);

            for my $fh (@ready) {
                my $buf;
                if ( $fh == $stdout_rdr->fileno() ) {
                    if ( 0 < sysread $stdout_rdr, $buf, $len ) {
                        $out .= $buf;
                    }
                    else {
                        $sel->remove($stdout_rdr->fileno());
                    }
                }
                elsif ( $fh == $stderr_rdr->fileno() ) {
                    if ( 0 < sysread $stderr_rdr, $buf, $len ) {
                        $err .= $buf;
                    }
                    else {
                        $sel->remove($stderr_rdr->fileno());
                    }
                }
            }

            $t = tv_interval($t0);
            last if $t >= $max_time;
            last if defined $rc;
        }

        if ( $t >= $max_time ) {
            # kill $child
            if ( !defined $rc && kill 0, $pid ) {
                kill 'TERM', $pid;
            }
            my $msg = "Timed out after ${max_time}s";
            $out .= $msg if !wantarray;
            $err .= $msg if wantarray;
        }

        return ( $rc, $out, $err )
            if wantarray;

        return $out;
    }
    elsif ( $pid == 0 ) {
        # child does not read anything from parent
        $stdout_rdr->close();
        $stderr_rdr->close();

        if ( ! open STDOUT, ">&", $stdout_wtr ) {
            croak("Could not reopen STDOUT: $!");
        }
        if ( ! open STDERR, ">&", $stderr_wtr ) {
            croak("Could not reopen STDERR: $!");
        }

        local $0 = $script;
        local @ARGV = @args;
        my $out = do "$script";
        if ( !defined $out ) {
            if ($@) {
                croak("Could not compile script $script: $@");
            }
            elsif ($!) {
                croak("Could not open script $script: $!");
            }
        }
        CORE::exit();
    }
    else {
        croak("Could not fork() in order to execute script $script!");
    }
}


1;

__END__

=head1 NAME
 
Perl::ScriptRunner - Run perl scripts with C<fork> and C<do>
 
=head1 SYNOPSIS
 
    use Perl::ScriptRunner;
    my $plrunner = Perl::ScriptRunner->new();
    my ( $rc, $out, $err ) = $plrunner->run( $script, @args );
 
=head1 DESCRIPTION

Perl::ScriptRunner allows execution of perl script utilizing C<fork> and
C<do>.  It prevents loading of another perl interpreter and provides
convenient way to retrieve return code, standard output, and standard error of
executed script.

=head2 Methods
 
=head3 new( [$opts] )
 
    my $plrunner = Perl::ScriptRunner->new( { timeout => 10 } );
 
Instantiates an object for later use. 
 
=head3 timeout([$timeout])

    $cur_timeout = $plrunner->timeout();
    $prev_timeout = $plrunner->timeout($new_timeout);

Get/set timeout in seconds for max time script can be allowed to execute
before it is terminated.

=head3 run( $script, @args )
 
    $stdout = $plrunner->run( $script, @args );
    ( $rc, $stdout, $stderr ) = $plrunner->run( $script, @args );
 
Run $script with @args.

In scalar context, returns value contains standard output from the command
being executed.  In list context, the values returned are the return code of
the command, standard output, and standard error.

=head1 BUGS AND LIMITATIONS

Execution of interactive scripcs is not supported.

Problematic scripts (causing memory leaks and such) executed through this
module are likely to cause same problems within app/script that use this
module.
 
=head1 SEE ALSO

<https://metacpan.org/pod/perlfunc#do-EXPR>


=head1 COPYRIGHT

This software is copyright (c) 2019 by Piotr Malek <pmalek426@gmail.com>.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
