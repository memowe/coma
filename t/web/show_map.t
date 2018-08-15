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

$t->get_ok('/map/1')->status_is(200)->text_is(h1 => 'Map Bar-Map');

# Description
my $description = $t->tx->res->dom->at('#description')->all_text;
is no_ws($description) => 'Yay Bar-Map!', 'Correct description';

# Note: visualization is ignored

subtest 'Entity cloud' => sub {
    my $cloud = $t->tx->res->dom->at('#entity_cloud');
    is $cloud->find('a')->size => 4, 'Four cloud items';
    is no_ws($cloud->all_text) => 'a b digit letter', 'Correct cloud';
};

subtest 'Entity table' => sub {
    my $entity_table = $t->tx->res->dom->at('table.entity_list');

    subtest 'Header' => sub {
        my $text = $entity_table->at('thead')->all_text;
        is no_ws($text) => 'Entity Reverse Pagerank Degree', 'Correct text';
    };

    subtest 'Data' => sub {
        my $table_data = $entity_table->find('tbody tr');
        is $table_data->size => 4, '4 data entries';

        # Retrieve data row texts as an array of strings
        my $data = $table_data->map(sub {no_ws($_->all_text)})->to_array;
        is_deeply $data => [
            'b 0.2880 3 (in: 2, out: 1)',
            'digit 0.2781 1 (in: 0, out: 1)',
            'a 0.2781 1 (in: 0, out: 1)',
            'letter 0.1557 1 (in: 1, out: 0)',
        ], 'Correct data rows';
    };
};

subtest 'Connections form listing' => sub {
    my $conn_items = $t->tx->res->dom('ol#connections li');
    is $conn_items->size => 3, 'Found three connections';

    # Retrieve item texts as an array of strings
    my $conns = $conn_items->map(sub {no_ws($_->all_text)})->to_array;
    is_deeply $conns => [
        'a is no b',
        'b is a letter',
        'digit has no b',
    ], 'Correct connections';
};

done_testing;

__END__
