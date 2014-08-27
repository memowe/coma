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

# map home
$t->get_ok('/')->text_is(h1 => 'Home');
$t->text_is('ul li:first-child a' => 'Beispiel');
my $map_url = $t->tx->res->dom->at('ul li:first-child a')->attr('href');

# map view
$t->get_ok($map_url)->text_is(h1 => 'Map Beispiel');

# map description (markdown)
$t->text_is('#description p' => 'Eine');
$t->text_is('#description p strong' => 'Beispiel-Concept-Map');

# make sure there's no foo map
my $map_links1 = $t->get_ok('/')->tx->res->dom('ul a');
my $foo_map_link = $map_links1->first(sub { shift->text eq 'foo' });
ok ! defined $foo_map_link, 'no foo map found';

# let's create one
$t->post_ok('/', form => {name => 'foo', description => 'bar'});
$t->text_is(h1 => 'Map foo')->text_is('#description p' => 'bar');

# is it listed?
my $map_links2 = $t->get_ok('/')->tx->res->dom('ul a');
is $map_links2->size, $map_links1->size + 1, 'one more map';
$foo_map_link = $map_links2->first(sub { shift->text eq 'foo' });
ok defined $foo_map_link, 'foo map found';

# remember id
my ($foo_map_id) = $foo_map_link->attr('href') =~ m|map/(\d+)|;

# change name and description
$t->post_ok("/map/$foo_map_id/edit", form => {
    name => 'baz', description => 'quux'
})->text_is(h1 => 'Map baz')->text_is('#description p' => 'quux');

# now delete it
$t->post_ok("/map/$foo_map_id/delete");
$t->text_is(h1 => 'Delete map baz');

# now delete it, really
$t->post_ok("/map/$foo_map_id/delete_sure");

# is it gone?
my $map_links3 = $t->tx->res->dom('ul a');
is $map_links3->size, $map_links1->size, 'one less map';
$foo_map_link = $map_links3->first(sub { shift->text eq 'foo' });
ok ! defined $foo_map_link, 'no foo map found';

done_testing;
