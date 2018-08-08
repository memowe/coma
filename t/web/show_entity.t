#!/usr/bin/env perl

use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Mojo;
use File::Temp 'tmpnam';
use FindBin '$Bin';

use Coma::Data;

sub no_ws ($input) {
    $input =~ s/^\s+//;
    $input =~ s/\s+$//;
    $input =~ s/\s+/ /g;
    return $input;
}

my $data_fn = tmpnam; # Scalar context neccessary
my $model = Coma::Data->new(data_filename => $data_fn);

# Disable event logging for tests
$model->logger(undef);

# Preparation
my $map1 = $model->add_map({name => 'Foo-Map', description => 'The Foo-Map!'});
$model->add_connection($map1, {from => 'a', type => 'is a', to => 'letter'});
$model->add_connection($map1, {from => 'digit', type => 'has no', to => 'a'});
my $map2 = $model->add_map({name => 'Bar-Map', description => 'Yay Bar-Map!'});
$model->add_connection($map2, {from => 'b', type => 'is a', to => 'letter'});
$model->add_connection($map2, {from => 'digit', type => 'has no', to => 'b'});
$model->add_connection($map2, {from => 'a', type => 'is no', to => 'b'});
$model->store;

# Inject the data into the coma app
$ENV{COMA_DATA_FILE} = $model->data_filename;
require "$Bin/../../coma";

# Prepare tester
my $t = Test::Mojo->new;
$t->app->data->logger(undef);

$t->get_ok('/entity/a')->status_is(200)->text_is(h1 => 'Entity a');

# Degree/Pagerank data
my $degrees = $t->tx->res->dom->at('#degrees');
is no_ws($degrees->all_text) =>
    'Degree: 3 (in: 1, out: 2) Reverse Pagerank: 0.2608',
    'Correct degree data';

subtest 'Incoming neighbourhood' => sub {
    my $in_n_table = $t->tx->res->dom->at('#in_neighbours table');

    subtest 'Header' => sub {
        my $header = $in_n_table->at('thead')->all_text;
        is no_ws($header) => 'Entity Reverse Pagerank Degree', 'Correct header';
    };

    subtest 'Data' => sub {
        my $table_data = $in_n_table->find('tbody tr');
        is $table_data->size => 1, 'One data entry';
        is no_ws($table_data->first->all_text) =>
            'digit 0.4278 2 (in: 0, out: 2)', 'Correct data';
    };
};

subtest 'Outgoing neighbourhood' => sub {
    my $out_n_table = $t->tx->res->dom->at('#out_neighbours table');

    subtest 'Header' => sub {
        my $header = $out_n_table->at('thead')->all_text;
        is no_ws($header) => 'Entity Reverse Pagerank Degree', 'Correct header';
    };

    subtest 'Data' => sub {
        my $table_data = $out_n_table->find('tbody tr');
        is $table_data->size => 2, 'One data entry';

        # Retrieve data row texts as an array of strings
        my $data = $table_data->map(sub {no_ws($_->all_text)})->to_array;
        is_deeply $data => [
            'b 0.1830 3 (in: 2, out: 1)',
            'letter 0.1284 2 (in: 2, out: 0)',
        ], 'Correct data rows';
    };
};

subtest 'Maps containing this entity' => sub {
    my $maps_links = $t->tx->res->dom('ul#containing_maps li');
    is $maps_links->size => 2, 'Two containing maps';
    is no_ws($maps_links->first->parent->all_text) => 'Bar-Map Foo-Map',
        'Correct containing maps';
};

done_testing;

__END__
