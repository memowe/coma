#!/usr/bin/env perl

use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Mojo;
use File::Temp qw(tmpnam tempdir);
use FindBin '$Bin';

sub no_ws ($input) {
    $input =~ s/^\s+//;
    $input =~ s/\s+$//;
    $input =~ s/\s+/ /g;
    return $input;
}

# Start the app without any data
$ENV{COMA_DATA_FILE}    = tmpnam;
$ENV{COMA_INIT_DIR}     = tempdir;
require "$Bin/../../coma";

# Prepare tester
my $t = Test::Mojo->new;
$t->ua->max_redirects(1);
$t->app->data->logger(undef);

subtest 'Empty home page' => sub {
    $t->get_ok('/')->status_is(200);
    is $t->tx->res->dom->find('ul#all_maps li')->size => 0, 'No maps';
};

# Store the map's ID
my $map_id;

subtest 'Add a map' => sub {

    subtest 'Add maps form exists' => sub {
        $t->element_exists('form#add_map[action=/]');
        $t->element_exists('form#add_map input[name=name]');
        $t->element_exists('form#add_map textarea[name=description]');
    };

    subtest 'Post' => sub {
        $t->post_ok('/', form => {name => 'foo', description => 'bar'});
        like $t->tx->req->url->path => qr|^/map/(\d+)$|,
            'Correct redirect URL';
        $t->tx->req->url->path =~ m|^/map/(\d+)$| and $map_id = $1;
    };

    subtest 'Check result' => sub {
        $t->status_is(200)->text_like(title => qr/Map foo/);
        is no_ws($t->tx->res->dom->at('#description')->all_text) => 'bar',
            'Correct description';
    };
};

subtest 'Update map data' => sub {

    subtest 'Update map data form exists' => sub {
        $t->element_exists("form#edit_map[action=/map/$map_id]");
        $t->element_exists('form#edit_map input[name=name][value=foo]');
        $t->text_is('form#edit_map textarea[name=description]' => 'bar');
    };

    subtest 'Post' => sub {
        $t->post_ok("/map/$map_id",
            form => {name => 'baz', description => 'quux'});
        is $t->tx->req->url->path => "/map/$map_id", 'Correct redirect URL';
    };

    subtest 'Check result' => sub {
        $t->status_is(200)->text_like(title => qr/Map baz/);
        is no_ws($t->tx->res->dom->at('#description')->all_text) => 'quux',
            'Correct description';
    };
};

subtest 'Add a connection' => sub {
    is $t->tx->res->dom('ol#connections li')->size => 0, 'No connections yet';

    subtest 'Add connection form exists' => sub {
        $t->element_exists(
            "form#add_connection[action=/map/$map_id/add_connection]");
        $t->element_exists('form#add_connection input[name=from]');
        $t->element_exists('form#add_connection input[name=type]');
        $t->element_exists('form#add_connection input[name=to]');
    };

    subtest 'Post' => sub {
        $t->post_ok("/map/$map_id/add_connection",
            form => {from => 'A', type => 'is a', to => 'B'});
        is $t->tx->req->url->path => "/map/$map_id", 'Correct redirect URL';
    };

    subtest 'Check result' => sub {
        $t->status_is(200);
        my $conn_data = $t->tx->res->dom('ol#connections li');
        is $conn_data->size => 1, 'One new connection';
        is no_ws($conn_data->first->all_text) => 'A is a B',
            'Correct new connection';
    };
};

subtest 'Delete a connection' => sub {
    my $conn_id;

    subtest 'Try to delete' => sub {
        $t->element_exists('ol#connections form.delete_connection'
            . "[action=/map/$map_id/delete_connection]");
        $t->element_exists('ol#connections form.delete_connection'
            . ' input[name=connection_id]');
        $conn_id = $t->tx->res->dom->at('ol#connections'
            . ' form.delete_connection input[name=connection_id]')
            ->attr('value');
    };

    subtest 'Check result' => sub {
        $t->post_ok("/map/$map_id/delete_connection",
            form => {connection_id => $conn_id});
        is $t->tx->req->url->path => "/map/$map_id", 'Correct redirect URL';
        $t->status_is(200)->tx->res->dom('ol#connections li')->size => 0,
            'Connection deleted';
    };
};

subtest 'Delete a map' => sub {

    subtest 'Try to delete' => sub {
        $t->element_exists("form#delete_map[action=/map/$map_id/delete]");
        $t->post_ok("/map/$map_id/delete");
        is $t->tx->req->url->path => "/map/$map_id/delete",
            'Correct redirect URL';
        $t->status_is(200)->text_like(title => qr/Delete map baz/);
    };

    subtest "I'm sure" => sub {
        $t->element_exists(
            "form#delete_map_sure[action=/map/$map_id/delete_sure]");
        $t->post_ok("/map/$map_id/delete_sure");
        is $t->tx->req->url->path => '/', 'Correct redirect URL';
        $t->status_is(200);
        is $t->tx->res->dom->find('ul#all_maps li')->size => 0, 'No maps';
    };
};

done_testing;

__END__
