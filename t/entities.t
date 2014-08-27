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

done_testing;
