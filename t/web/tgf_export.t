#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Mojo;
use File::Temp;
use FindBin;

use Coma::Data;

my $data_fn = File::Temp::tmpnam; # scalar context neccessary
my $model = Coma::Data->new(data_filename => $data_fn);

# Disable event logging for tests
$model->logger(undef);

# Preparation
my $map_id = $model->add_map({name => 'foo', description => 'bar'});
$model->add_connection($map_id, {from => 'ADA', type => 'ind', to => 'YOLO'});
$model->add_connection($map_id, {from => 'YALA', type => 'and', to => 'ADA'});
$model->store;

# Get the lite script
$ENV{COMA_DATA_FILE} = $model->data_filename;
require "$FindBin::Bin/../../coma";

# Prepare tester
my $t = Test::Mojo->new;

subtest 'No matching map' => sub {
    $t->get_ok('/map/42/tgf_export')->status_is(404);
};

subtest 'TGF export' => sub {
    $t->get_ok("/map/$map_id/tgf_export")->status_is(200);
    $t->header_is(
        'Content-Disposition' => "attachment; filename=map_foo_$map_id.tgf",
    );
    $t->content_is(<<'TGF1');
1 ADA
2 YALA
3 YOLO
#
1 3 ind
2 1 and
TGF1
};

done_testing;

__END__
