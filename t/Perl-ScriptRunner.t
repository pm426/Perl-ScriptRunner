#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

#use Data::Dumper;
use Test::More tests => 12;


BEGIN { use_ok('Perl::ScriptRunner') };


my $script = "$FindBin::Bin/cmd/script.pl";
my ( $rc, $stdout, $stderr );
my $plrunner = Perl::ScriptRunner->new( { timeout => 10 } );


# script with stdout and stderr followed by exits
( $rc, $stdout, $stderr ) = $plrunner->run( $script,
    qw/ --type exit --stdout foo --stderr bar / );
chomp $stdout if defined $stdout;
chomp $stderr if defined $stderr;
ok( 'foo' eq $stdout, 'stdout with exit' );
ok( 'bar' eq $stderr, 'stderr with exit' );
ok( 42 == $rc >> 8, 'rc with exit' );


# script that dies
( $rc, $stdout, $stderr ) = $plrunner->run( $script,
    qw/ --type die --stdout foo --stderr bar / );
chomp $stdout if defined $stdout;
chomp $stderr if defined $stderr;
ok( 'foo' eq $stdout, 'stdout with die' );
like( $stderr, qr/bar/, 'stderr with die' );
like( $stderr, qr/Could not compile script/, 'has die reason ' );
ok( 255 == $rc >> 8, 'rc with die' );


# non perl script
my $non_pl_script = "$FindBin::Bin/cmd/test.sh";
( $rc, $stdout, $stderr ) = $plrunner->run( $non_pl_script, qw// );
like( $stderr, qr/Could not compile script/, 'non pl script' );


# missing script cannot be open
( $rc, $stdout, $stderr ) = $plrunner->run( './missing_script.pl', qw// );
like( $stderr, qr/Could not open script/, 'missing script error' );


# script with compile errors
my $script_w_errors = "$FindBin::Bin/cmd/error_test.pl";
( $rc, $stdout, $stderr ) = $plrunner->run( $script_w_errors, qw// );
like( $stderr, qr/Could not compile script/, 'script with errors' );


# script that will timeout
# XXX: test can be broken on vms
my $script_w_sleep = "$FindBin::Bin/cmd/timeout.pl";
$plrunner->timeout(2);
( $rc, $stdout, $stderr ) = $plrunner->run( $script_w_sleep, qw// );
like( $stderr, qr/Timed out after/, 'timed out' );
# reset the timeout
$plrunner->timeout(10);
