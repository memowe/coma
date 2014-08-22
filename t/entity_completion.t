#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use FindBin '$Bin';

# get the lite script
require "$Bin/../coma.pl";

# prepare
my $t = Test::Mojo->new;

# try to find some example entities with 'a'
$t->get_ok('/entity_completion?term=a');
my @entities = @{$t->tx->res->json};
ok @entities > 0, 'found an entity';
is scalar(grep /a/ => @entities), scalar(@entities), 'all entities';
ok 'Informatik' ~~ @entities, 'found "Informatik"';
ok 'Programmiersprache' ~~ @entities, 'found "Programmiersprache"';
ok ! ('Funktion' ~~ @entities), '"Funktion" not found';

# try to find some example entities with 'ti'
$t->get_ok('/entity_completion?term=ti');
@entities = @{$t->tx->res->json};
ok @entities > 0, 'found an entity';
is scalar(grep /ti/ => @entities), scalar(@entities), 'all entities';
ok 'Informatik' ~~ @entities, 'found "Informatik"';
ok 'Funktion' ~~ @entities, 'found "Funktion"';
ok ! ('Programmiersprache' ~~ @entities), '"Programmiersprache not found';

# try to find some example entities with 'xnorfzt'
$t->get_ok('/entity_completion?term=xnorfzt');
@entities = @{$t->tx->res->json};
is @entities, 0, 'nothing found';

done_testing;
