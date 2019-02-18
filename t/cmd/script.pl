#!/usr/bin/env perl 

use strict;
use warnings;

use Getopt::Long;

my $USAGE = <<END_USAGE
$0 [-v] [-d] [-h]

END_USAGE
;

my $opt_parser = Getopt::Long::Parser->new();
$opt_parser->configure( qw/ no_ignore_case / );
my %option;
my $result = GetOptions(
        \%option,
        'type=s',
        'stdout=s',
        'stderr=s',
        'debug',
        'verbose',
        'help',
        );

if ( !$result || $option{'help'} ) {
    die $USAGE;
}
if ( !defined $option{'type'} ) {
    die $USAGE;
}

print STDOUT $option{'stdout'} . "\n"
    if defined $option{'stdout'};
print STDERR $option{'stderr'} . "\n"
    if defined $option{'stderr'};

if ( $option{'type'} eq 'exit' ) {
    exit 42;
}
elsif ( $option{'type'} eq 'die' ) {
    die "asked to die";
}
else {
    # no op
    my $foo = 37;
}
