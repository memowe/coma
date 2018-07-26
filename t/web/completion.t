#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Mojo;
use File::Temp 'tmpnam';
use FindBin '$Bin';

use Coma::Data;

my $data_fn = File::Temp::tmpnam; # Scalar context neccessary
my $model = Coma::Data->new(data_filename => $data_fn);

# Disable event logging for tests
$model->logger(undef);

# Preparation
my $map = $model->add_map({name => 'foo', description => 'bar'});
$model->add_connection($map, {from => 'ADA', type => 'ind', to => 'YOLO'});
$model->add_connection($map, {from => 'YALA', type => 'and', to => 'ADA'});
$model->store;

# Get the lite script
$ENV{COMA_DATA_FILE} = $model->data_filename;
require "$Bin/../../coma";

# Prepare tester
my $t = Test::Mojo->new;

subtest 'Entities' => sub {
    
    subtest 'None' => sub {
        $t->get_ok('/entity_completion?term=X');
        my $es = $t->tx->res->json;
        ok @$es == 0, 'No entities found';
    };

    subtest 'One' => sub {
        $t->get_ok('/entity_completion?term=YO');
        my $es = $t->tx->res->json;
        ok is_deeply $es => ['YOLO'], 'One entity found';
    };

    subtest 'More' => sub {
        $t->get_ok('/entity_completion?term=A');
        my $es = $t->tx->res->json;
        ok is_deeply $es => [qw(ADA YALA)], 'Two entities found';
    };
};

subtest 'Connections' => sub {

    subtest 'None' => sub {
        $t->get_ok('/connection_completion?term=und');
        my $cs = $t->tx->res->json;
        ok @$cs == 0, 'No entities found';
    };

    subtest 'One' => sub {
        $t->get_ok('/connection_completion?term=and');
        my $cs = $t->tx->res->json;
        ok is_deeply $cs => ['and'], 'One entity found';
    };

    subtest 'More' => sub {
        $t->get_ok('/connection_completion?term=nd');
        my $cs = $t->tx->res->json;
        ok is_deeply $cs => [qw(and ind)], 'Two entities found';
    };
};

done_testing;

__END__
