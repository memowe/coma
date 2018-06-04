#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use_ok 'Coma::Data';
my $model = Coma::Data->new;

# Disable event logging for tests as events are tested in EventStore::Tiny
$model->events->_est->logger(undef);

# Global test data
my $map_id;

subtest 'Add map' => sub {

    # Add
    $map_id = $model->add_map({name => 'foo', description => 'bar'});

    # Check generated ID
    ok defined($map_id), 'Generated ID is defined';
    like $map_id => qr/^\d+$/, 'Generated ID is a number';
};

subtest 'Load maps' => sub {

    # List all maps
    is_deeply $model->get_all_map_ids => [$map_id], 'Correct map ID list';

    # Retrieve the only map
    my $data = $model->get_map_data($map_id);

    # Check the only map's data
    ok defined($data), 'Retrieved data is defined';
    is_deeply $data => {
        name        => 'foo',
        description => 'bar',
        id          => $map_id,
    }, 'Retrieved map data is correct';
};

subtest 'Update map' => sub {

    # Update the only map
    $model->update_map_data($map_id, {
        name        => 'baz',
        description => 'quux',
    });

    # Check map list
    is_deeply $model->get_all_map_ids => [$map_id], 'Map ID list unchanged';

    # Retrieve the only map
    my $data = $model->get_map_data($map_id);

    # Check its data
    ok defined($data), 'Retrieved data is defined';
    is_deeply $data => {
        name        => 'baz',
        description => 'quux',
        id          => $map_id,
    }, 'Retrieved map data is correct';
};

subtest 'Remove map' => sub {

    # Remember map data
    my $map_data = $model->get_map_data($map_id);

    # Delete it from the model
    $model->remove_map($map_id);
    is_deeply $model->get_all_map_ids => [], 'No maps left';

    # "Undo" removal
    delete $map_data->{id};
    $map_id = $model->add_map($map_data);
    is_deeply $model->get_map_data($map_id) => {%$map_data, id => $map_id},
        'Map removal undone';
};

# TODO

done_testing;

__END__
