#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Mojo;
use File::Temp 'tmpnam';
use FindBin '$Bin';

use Coma::Data;

# Inject coma initialization data without having persistent data
# as this gives us a name of a temporary file without creating it.
$ENV{COMA_DATA_FILE} = tmpnam; # Scalar context neccessary
$ENV{COMA_INIT_DIR}  = $Bin;
require "$Bin/../../../coma";

# Prepare tester
my $t = Test::Mojo->new;

# Test init data presence
my $map_ids = $t->app->data->get_all_map_ids;
ok @$map_ids == 1, 'Only one map ID found';
my $map_id = $map_ids->[0];
is_deeply $t->app->data->get_map_data($map_id), {
    name => 'foo', description => '', id => $map_id,
    connections => {0 => {
        from => 'baz', to => 'bar', type => 'quux',
        map => $map_id, id => 0,
    }},
}, 'Correct initialization map';

done_testing;

__END__
