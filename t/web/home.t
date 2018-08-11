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

$t->get_ok('/')->status_is(200)->text_is(h1 => 'Home');

subtest 'Maps list' => sub {
    my $maps_links = $t->tx->res->dom('ul#all_maps li');
    is $maps_links->size => 2, 'Two maps';
    is no_ws($maps_links->first->parent->all_text) => 'Bar-Map Foo-Map',
        'Correct maps';
};

done_testing;

__END__
