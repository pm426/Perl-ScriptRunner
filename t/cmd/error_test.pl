#!/usr/bin/env perl

use strict;
use warnings;

my foo; # XXX: intentional error
my $bar = Some::Missing::Module->new(); # XXX: intentional error;
