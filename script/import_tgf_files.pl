#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';

use FindBin '$Bin';
use lib "$Bin/lib";
use ComaDB;

# no log caching
$| = 42;

# connect to database
my $dbfile = $ENV{COMA_DB} // "$Bin/data/graph.sqlite";
my $schema = ComaDB->connect("dbi:SQLite:$dbfile", '', '', {
    AutoCommit      => 1,
    RaiseError      => 1,
    sqlite_unicode  => 1,
});

# iterate over file names
while (defined(my $filename = <STDIN>)) {
    chomp $filename;

    # valid file?
    die "invalid filename: $filename" unless -r $filename;

    # open that file
    open my $fh, '<:encoding(UTF-8)', $filename
        or die "couldn't open $filename: $!";

    # iterate lines
    say "processing $filename...";
    my %concept = ();
    my @links   = ();
    while (<$fh>) {
        chomp $_;

        # file section markers (this is magic)
        my $concept_section = 1 .. /^#$/;
        my $link_section    = /^#$/ .. eof;

        # first section: concepts like "12345 foo"
        if ($concept_section and /^(\d+) (.*)/) {
            $concept{$1} = $2;
        } 

        # second section: links like "23456 34567 bar"
        if ($link_section and /^(\d+) (\d+) (.*)/) {
            warn "unknown concept $1\n" unless exists $concept{$1};
            warn "unknown concept $2\n" unless exists $concept{$2};
            push @links, {
                from_name   => $concept{$1},
                to_name     => $concept{$2},
                type        => $3,
            };
        }
    }

    # delete duplicate links
    my %unique_links = ();
    $unique_links{"$_->{from_name}-$_->{type}-$_->{to_name}"} = $_ for @links;
    my @unique_links = values %unique_links;

    # log
    my $concept_c   = keys %concept;
    my $link_c      = @links;
    my $dupl_link_c = @links - @unique_links;
    say "    $concept_c concepts and $link_c links ($dupl_link_c duplicates)";

    # prepare group identification
    my $group_name = $filename =~ m|([^\\/]+)\.tgf$| ? $1 : 'unknown';

    # create it in the database
    my $map = $schema->resultset('Map')->create({
        name        => $group_name,
        description => "Informatik I WS1415 contents according to $group_name",
        connections => \@unique_links,
    });

    # done
    say '  done.';
}
