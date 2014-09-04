#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin '$Bin';

# find test database
my $test_db_file = "$Bin/graph.sqlite";
ok -e $test_db_file, 'test database found';

# kill it and test for it
unlink $test_db_file or die "couldn't delete test db: $!\n";
ok ! -e $test_db_file, 'test database gone';

done_testing;
