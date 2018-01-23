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
require "$Bin/../coma";

# prepare
my $t = Test::Mojo->new;
$t->ua->max_redirects(1);

# find three entities in the entity cloud
my $text = $t->get_ok('/map/1')->tx->res->dom('#entitycloud')->first->all_text;
like $text => qr/JVM/, 'found JVM in the cloud';
like $text => qr/Java/, 'found Java in the cloud';

# entity list
my $entity_table = $t->tx->res->dom->at('.neighbours');
my $out_table_data = $entity_table->find('tbody tr');
is $out_table_data->size, 3, 'two outgoing neighbours found';
my $first_out = $out_table_data->slice(0)->first;
like $first_out->all_text, qr/Java\s+0.5209\s+2\s+\(in: 0, out: 2\)/,
    'Java found';
my $second_out = $out_table_data->slice(1)->first;
like $second_out->all_text, qr/Programmiersprache\s+0.2816\s+2\s+\(in: 1, out: 1\)/, 'Programmiersprache found';
my $third_out = $out_table_data->slice(2)->first;
like $third_out->all_text, qr/JVM\s+0.1976\s+2\s+\(in: 2, out: 0\)/,
    'JVM found';

done_testing;
