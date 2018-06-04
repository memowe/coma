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

subtest 'Map handling' => sub {

    subtest Create => sub {

        # Add
        $map_id = $model->add_map({name => 'foo', description => 'bar'});

        # Check generated ID
        ok defined($map_id), 'Generated ID is defined';
        like $map_id => qr/^\d+$/, 'Generated ID is a number';
    };

    subtest Read => sub {

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

    subtest Update => sub {

        # Update the only map
        $model->update_map_data($map_id, {
            name        => 'baz',
            description => 'quux',
        });

        # Check map list
        is_deeply $model->get_all_map_ids => [$map_id],
            'Map ID list unchanged';

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

    subtest Delete => sub {

        # Remember map data
        my $map_data = $model->get_map_data($map_id);

        # Delete it from the model
        $model->remove_map($map_id);
        is_deeply $model->get_all_map_ids => [], 'No maps left';

        # "Undo" removal
        delete $map_data->{id};
        $map_id = $model->add_map($map_data);
        is_deeply $model->get_map_data($map_id),
            {%$map_data, id => $map_id}, 'Map removal undone';
    };
};

subtest 'Connection handling' => sub {

    # Connection test data
    my $c_id;

    subtest Create => sub {

        # Add
        $c_id = $model->add_connection($map_id, {
            from    => 'Patch',
            type    => 'fixes',
            to      => 'Bug',
        });

        # Check generated ID
        ok defined($c_id), 'Generated ID is defined';
        like $c_id => qr/^\d+$/, 'Generated ID is a number';
    };

    subtest Read => sub {

        # Retrieve from map data
        my $cs = $model->get_map_data($map_id)->{connections};
        is_deeply $cs => {$c_id => {map => $map_id, id => $c_id,
            from    => 'Patch',
            type    => 'fixes',
            to      => 'Bug',
        }}, 'Correct connection data retrieved from map data';
    };

    subtest Update => sub {

        # Update
        $model->update_connection($map_id, $c_id, {
            from    => 'A',
            type    => 'to',
            to      => 'B',
        });

        # Check if the only connection has changed
        my $cs = $model->get_map_data($map_id)->{connections};
        is_deeply $cs => {$c_id => {map => $map_id, id => $c_id,
            from    => 'A',
            type    => 'to',
            to      => 'B',
        }}, 'Correct connection data retrieved from map data';
    };

    subtest Delete => sub {

        # Delete it
        $model->remove_connection($map_id, $c_id);

        # Retrieve connections from map data
        is_deeply $model->get_map_data($map_id)->{connections} => {},
            'No connections left';
    };
};

subtest 'Data extraction' => sub {

    # Preparation
    my $map_id = $model->add_map({name => 'foo', description => 'bar'});
    $model->add_connection($map_id, {from => 'X', type => 'and', to => 'Y'});
    $model->add_connection($map_id, {from => 'WTF', type => 'yo', to => 'X'});

    # Check sorted entity list
    subtest 'Entity listing' => sub {
        is_deeply $model->get_map_entities($map_id) => [qw(WTF X Y)],
            'Correct map entities';
    };
};

done_testing;

__END__
