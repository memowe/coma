#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use FindBin '$Bin';

# prepare test database
$ENV{COMA_DB} = "$Bin/graph.sqlite";
ok -e $ENV{COMA_DB}, 'test database found';

# get the lite script
require "$Bin/../coma.pl";

# prepare
my $t = Test::Mojo->new;
$t->ua->max_redirects(1);

# find three things in the entity cloud
my $text = $t->get_ok('/entities')->tx->res->dom('#entitycloud')->all_text;
like $text => qr/JVM/, 'found JVM in the cloud';
like $text => qr/Java/, 'found Java in the cloud';
like $text => qr/Programmiersprache/, 'found Programmiersprache in the cloud';

# inspect an entity page
$t->get_ok('/entity/Java')->text_is(h1 => 'Entity Java');

# degree
$t->text_is('#degrees' => '3 (in: 0, out: 3)');

# neighbourhood
my $neighbour_tables = $t->tx->res->dom('.neighbours');
my $in_table_data = $neighbour_tables->slice(0)->first->find('tbody tr');
is $in_table_data->size, 0, 'no incoming neighbours';
my $out_table_data = $neighbour_tables->slice(1)->first->find('tbody tr');
is $out_table_data->size, 2, 'two outgoing neighbours found';
my $first_out = $out_table_data->slice(0)->first;
is $first_out->all_text, 'Programmiersprache 0.2597 2 (in: 1, out: 1)', 'Programmiersprache found';
my $second_out = $out_table_data->slice(1)->first;
is $second_out->all_text, 'JVM 0.2024 3 (in: 3, out: 0)', 'JVM found';

done_testing;
