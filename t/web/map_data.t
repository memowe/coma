#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Mojo;
use File::Temp qw(tmpnam tempdir);
use FindBin '$Bin';

# Prepare an empty coma app
$ENV{COMA_DATA_FILE} = tmpnam;
$ENV{COMA_INIT_DIR}  = tempdir;
require "$Bin/../../coma";
my $t = Test::Mojo->new;

# Disable logging
$t->app->data->logger(undef);

# Enter map data
my $map_id = $t->app->data->add_map({name => 'foo', description => 'bar'});
my $con_id = $t->app->data->add_connection($map_id, {
    from    => 'baz',
    type    => 'quux',
    to      => 'quuux',
});

$t->get_ok("/map/$map_id/d3_map_data.json");

ok keys %{$t->tx->res->json} == 2, 'Correct data size';

is_deeply $t->tx->res->json->{nodes} => [
    {name => 'baz',     pagerank => 0.649122806021908},
    {name => 'quuux',   pagerank => 0.350877193978092},
], 'Correct entities';

is_deeply $t->tx->res->json->{links} => [{
    source  => 'baz',
    type    => 'quux',
    target  => 'quuux',
}], 'Correction connections';

done_testing;

__END__
