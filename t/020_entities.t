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
my $entities_res = $t->get_ok('/entities')->tx->res;
my $text = $entities_res->dom('#entitycloud')->first->all_text;
like $text => qr/JVM/, 'found JVM in the cloud';
like $text => qr/Java/, 'found Java in the cloud';
like $text => qr/Programmiersprache/, 'found Programmiersprache in the cloud';

# entity table (sorted by pagerank)
my $table_data = $t->tx->res->dom('table.neighbours tbody tr');
is $table_data->size, 3, 'right number of entities found';
my $first_row = $table_data->slice(0)->first->all_text;
like $first_row, qr/Java\s+0.5379\s+3\s+\(in: 0, out: 3\)/, 'Java found';
my $second_row = $table_data->slice(1)->first->all_text;
like $second_row, qr/Programmiersprache\s+0.2597\s+2\s+\(in: 1, out: 1\)/, 'Programmiersprache found';
my $third_row = $table_data->slice(2)->first->all_text;
like $third_row, qr/JVM\s+0.2024\s+3\s+\(in: 3, out: 0\)/, 'JVM found';

# inspect an entity page
$t->get_ok('/entity/Java')->text_is(h1 => 'Entity Java');

# degree
$t->text_like('#degrees' => qr/3\s+\(in: 0, out: 3\)/);

# neighbourhood
my $neighbour_tables = $t->tx->res->dom('.neighbours');
my $in_table_data = $neighbour_tables->slice(0)->first->find('tbody tr');
is $in_table_data->size, 0, 'no incoming neighbours';
my $out_table_data = $neighbour_tables->slice(1)->first->find('tbody tr');
is $out_table_data->size, 2, 'two outgoing neighbours found';
my $first_out = $out_table_data->slice(0)->first;
like $first_out->all_text, qr/Programmiersprache\s+0.2597\s+2\s+\(in: 1, out: 1\)/, 'Programmiersprache found';
my $second_out = $out_table_data->slice(1)->first;
like $second_out->all_text, qr/JVM\s+0.2024\s+3\s+\(in: 3, out: 0\)/, 'JVM found';

# all maps with this entity
my $map_links = $t->tx->res->dom('ul a');
is $map_links->size, 2, 'two maps';
is $map_links->slice(0)->first->all_text, 'Beispiel', 'Beispiel found';
is $map_links->slice(1)->first->all_text, 'Bleistift', 'Bleistift found';

# all maps with entity Programmiersprache
$map_links = $t->get_ok('/entity/Programmiersprache')->tx->res->dom('ul a');
is $map_links->size, 1, 'only one map';
is $map_links->map('text')->join(' '), 'Beispiel', 'Beispiel found';

done_testing;
