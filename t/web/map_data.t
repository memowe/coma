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

subtest 'Entity data' => sub {
    $t->get_ok("/map/$map_id/entities.json");
    is_deeply $t->tx->res->json => ['baz', 'quuux'], 'Correct entities';
};

subtest 'Connection data' => sub {
    $t->get_ok("/map/$map_id/connections.json");
    is_deeply $t->tx->res->json => [{
        from    => 'baz',
        type    => 'quux',
        to      => 'quuux',
        id      => $con_id,
        map     => $map_id,
    }], 'Correction connection data';
};

done_testing;

__END__
