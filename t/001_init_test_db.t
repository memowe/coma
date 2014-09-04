#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin '$Bin';

use lib "$Bin/../lib";
use ComaDB;

# prepare test database
my $test_db_file = "$Bin/graph.sqlite";
ok ! -e $test_db_file, 'no test database found';

# create the database and build schema
my $schema_file = "$Bin/../data/schema.sql";
system "sqlite3 $test_db_file < $schema_file";
ok -e $test_db_file, 'test database created';

# connect to the database
my $db = ComaDB->connect("dbi:SQLite:$test_db_file", '', '', {
    AutoCommit      => 1,
    RaiseError      => 1,
    sqlite_unicode  => 1,
});

# insert test data: maps
$db->resultset('Map')->create({
    id          => 1,
    name        => 'Beispiel',
    description => 'Eine **Beispiel-Concept-Map**',
});
$db->resultset('Map')->create({
    id          => 2,
    name        => 'Bleistift',
    description => 'Eine andere Beispiel-Concept-Map',
});

# test if it's there
my @maps = $db->resultset('Map')->all;
is scalar(@maps), 2, 'right number of maps';
my ($beispiel, $bleistift) = @maps;
is $beispiel->id, 1, 'Beispiel: right id';
is $beispiel->name, 'Beispiel', 'Beispiel: right name';
is $beispiel->description, 'Eine **Beispiel-Concept-Map**', 'Beispiel: right description';
is $bleistift->id, 2, 'Bleistift: right id';
is $bleistift->name, 'Bleistift', 'Bleistift: right name';
is $bleistift->description, 'Eine andere Beispiel-Concept-Map', 'Bleistift: right description';

# insert test data: connections
$db->resultset('Connection')->create({
    map_id      => 1,
    from_name   => 'Java',
    type        => 'isa',
    to_name     => 'Programmiersprache',
});
$db->resultset('Connection')->create({
    map_id      => 1,
    from_name   => 'Java',
    type        => 'has',
    to_name     => 'JVM',
});
$db->resultset('Connection')->create({
    map_id      => 1,
    from_name   => 'Programmiersprache',
    type        => 'isa',
    to_name     => 'JVM',
});
$db->resultset('Connection')->create({
    map_id      => 2,
    from_name   => 'Java',
    type        => 'has',
    to_name     => 'JVM',
});

# Beispiel map: test if all connections are there
is_deeply [sort map "$_" => $beispiel->search_related('connections')->all], [
    'Java -has-> JVM',
    'Java -isa-> Programmiersprache',
    'Programmiersprache -isa-> JVM',
], 'Beispiel: right connections';

# Bleistift map: test if all connections are there
is_deeply [sort map "$_" => $bleistift->search_related('connections')->all], [
    'Java -has-> JVM',
], 'Bleisftift: right connections';

done_testing;
