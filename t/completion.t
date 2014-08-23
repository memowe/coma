#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use FindBin '$Bin';

# prepare test database
$ENV{COMA_DB} = "$Bin/graph.sqlite";
ok ! -e $ENV{COMA_DB}, 'no test database found';

# get the lite script
require "$Bin/../coma.pl";

# got a test database?
ok -e $ENV{COMA_DB}, 'test database found';

# prepare
my $t = Test::Mojo->new;

# try to find some example entities with 'a'
$t->get_ok('/entity_completion?term=a');
my @entities = @{$t->tx->res->json};
ok @entities > 0, 'found an entity';
is scalar(grep /a/i => @entities), scalar(@entities), 'all entities';
ok 'Programmiersprache' ~~ @entities, 'found "Programmiersprache"';
ok 'Java' ~~ @entities, 'found "Java"';
ok ! ('JVM' ~~ @entities), '"JVM" not found';

# try to find some example entities with 'j'
$t->get_ok('/entity_completion?term=j');
@entities = @{$t->tx->res->json};
ok @entities > 0, 'found an entity';
is scalar(grep /j/i => @entities), scalar(@entities), 'all entities';
ok 'Java' ~~ @entities, 'found "Java"';
ok 'JVM' ~~ @entities, 'found "JVM"';
ok ! ('Programmiersprache' ~~ @entities), '"Programmiersprache" not found';

# try to find some example entities with 'xnorfzt'
$t->get_ok('/entity_completion?term=xnorfzt');
@entities = @{$t->tx->res->json};
is scalar(@entities), 0, 'nothing found';

# try to find some example connection types with 's'
$t->get_ok('/connection_completion?term=s');
my @types = @{$t->tx->res->json};
ok @types > 0, 'found a connection';
is scalar(grep /s/i => @types), scalar(@types), 'all types';
is scalar(keys %{{map $_ => 1 => @types}}), scalar(@types), 'unique types';
ok 'isa' ~~ @types, 'found "isa"';
ok 'has' ~~ @types, 'found "has"';

# try to find some example connection types with 'h'
$t->get_ok('/connection_completion?term=h');
@types = @{$t->tx->res->json};
ok @types > 0, 'found a connection';
is scalar(grep /h/i => @types), scalar(@types), 'all types';
is scalar(keys %{{map $_ => 1 => @types}}), scalar(@types), 'unique types';
ok 'has' ~~ @types, 'found "has"';
ok ! ('isa' ~~ @types), '"isa" not found';

# try to find some example connection types with 'xnorfzt'
$t->get_ok('/connection_completion?term=xnorfzt');
@types = @{$t->tx->res->json};
is scalar(@types), 0, 'nothing found';

# cleanup
unlink $ENV{COMA_DB};
ok ! -e $ENV{COMA_DB}, 'test database removed';

done_testing;
