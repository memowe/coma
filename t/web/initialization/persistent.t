#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Mojo;
use File::Temp 'tmpnam';
use FindBin '$Bin';

use Coma::Data;

# Write to temporary persistent data storage
my $fn      = tmpnam;
my $model   = Coma::Data->new;
my $map_id  = $model->add_map({name => 'a', description => 'b'});
my $conn_id = $model->add_connection($map_id, {
    from => 'c', type => 'd', to => 'e',
});
$model->events->data_filename($fn);
$model->store;

# Inject the temporary persistent data storage
# and the same init dir
$ENV{COMA_DATA_FILE} = $fn;
$ENV{COMA_INIT_DIR}  = $Bin;
require "$Bin/../../../coma";

# Prepare tester
my $t = Test::Mojo->new;

# Test persistent data and absence of init data
my $map_ids = $t->app->data->get_all_map_ids;
ok @$map_ids == 1, 'Only one map ID found';
is $map_ids->[0] => $map_id, 'Same map ID';
is_deeply $t->app->data->get_map_data($map_id), {
    name => 'a', description => 'b', id => $map_id,
    connections => {0 => {
        from => 'c', type => 'd', to => 'e',
        map => $map_id, id => 0,
    }},
}, 'Correct persistent data map';

done_testing;

__END__
