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
$t->ua->max_redirects(1);

# map overview
$t->get_ok('/')->text_is(h1 => 'Map overview');
$t->text_is('ul li:first-child a' => 'Beispiel');
my $map_url = $t->tx->res->dom->at('ul li:first-child a')->attr('href');

# map view
$t->get_ok($map_url)->text_is(h1 => 'Map Beispiel');

# map descript (markdown)
$t->text_like('#description p' => qr/Eine/);
$t->text_like('#description p strong' => qr/Beispiel-Concept-Map/);

# cleanup
unlink $ENV{COMA_DB};
ok ! -e $ENV{COMA_DB}, 'test database removed';

done_testing;
