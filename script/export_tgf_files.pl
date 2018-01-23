#!/usr/bin/env perl

# exports all map in the database to TGF files in the export directory
# WARNING: the descriptions are lost - which is not bad for many old maps

use strict;
use warnings;
use feature 'say';

use FindBin '$Bin';
use lib "$Bin/../lib";
use ComaDB;

# no log caching
$| = 42;

# prepare output directory
my $export_dir = "$Bin/export";

# create if neccessary
mkdir $export_dir unless -d $export_dir;

# connect to database
my $dbfile = $ENV{COMA_DB} // "$Bin/../data/graph.sqlite";
my $schema = ComaDB->connect("dbi:SQLite:$dbfile", '', '', {
    AutoCommit      => 1,
    RaiseError      => 1,
    sqlite_unicode  => 1,
});

# iterate all maps
for my $map ($schema->resultset('Map')->all) {

    # prepare output file
    my $output_fn = $export_dir . '/' . $map->name . '.tgf';
    open my $out, '>:encoding(UTF-8)', $output_fn
        or die "Couldn't open export file '$output_fn': $!\n";

    # log
    print "Writing $output_fn...";

    # dump TGF data
    print $out $map->to_tgf;

    # done
    close $out;
    print " done.\n";
}
