#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp;
use File::stat;

use_ok 'Coma::Data';

# Create a temporary file
my $tmpf    = File::Temp->new;
my $fn      = $tmpf->filename;

# Prepare
my $model = Coma::Data->new;
$model->logger(undef);
my $map_id = $model->add_map({name => 'foo', description => 'bar'});
my $conn_id;
$model->events->data_filename($fn);

subtest 'Initial emptiness' => sub {
    is $model->last_storage => 0, 'Last storage timestamp is 0';
    is stat($tmpf)->size => 0, 'File still empty';
};

# Store
$model->store;

subtest 'Stored correctly' => sub {
    ok 1 >= time - $model->last_storage, 'There was an update';
    ok stat($tmpf)->size != 0, 'File not empty';
    ok 1 > time - stat($tmpf)->mtime, 'File modified recently';

    # Read from it
    my $m2 = Coma::Data->new(data_filename => $fn);
    my $m2_data = $m2->get_map_data($map_id);
    is $m2_data->{name} => 'foo', 'Correct map name';
    is $m2_data->{description} => 'bar', 'Correct map description';
};

subtest 'Storage neccessary?' => sub {

    subtest 'No' => sub {
        sleep 1; # Wait to see a difference in timestamps
        ok ! $model->store_if_neccessary, 'Storage not neccessary';
        ok 1 <= time - stat($tmpf)->mtime, 'File not modified';
    };

    subtest 'Yes' => sub {
        sleep 1; # Wait to see a difference in timestamps
        $conn_id = $model->add_connection($map_id, {
            from => 'a', type => 'to', to => 'b',
        });
        ok $model->store_if_neccessary, 'Storage neccessary';
        ok 1 > time - stat($tmpf)->mtime, 'File modified';

        # Check content
        my $m2 = Coma::Data->new(data_filename => $fn);
        my $m2_data = $m2->get_map_data($map_id);
        is $m2_data->{name} => 'foo', 'Correct map name';
        is $m2_data->{description} => 'bar', 'Correct map description';
        is_deeply $m2_data->{connections}{$conn_id} => {
            from => 'a', type => 'to', to => 'b',
            id => $conn_id, map => $map_id,
        }, 'Correct connection';
    };
};

done_testing;
