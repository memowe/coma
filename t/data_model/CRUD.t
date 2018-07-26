#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp;

use_ok 'Coma::Data';
my $model = Coma::Data->new;

subtest 'Logger handling' => sub {
    my $rand = rand;
    $model->logger($rand);
    is $model->events->_est->logger => $rand, 'Correct logger set';
};

# Disable event logging for tests as events are tested in EventStore::Tiny
$model->logger(undef);

subtest 'Emptiness' => sub {
    ok $model->is_empty, 'Model is empty after creation';
    is $model->last_update => 0, 'No updates yet';
};

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

subtest 'Trivial Graph Format (TGF) handling' => sub {

    subtest 'Export' => sub {

        # Preparation
        my $map1 = $model->add_map({name => 'foo', description => 'bar'});
        $model->add_connection($map1, {from => 'X', type => 'and', to => 'Y'});
        $model->add_connection($map1, {from => 'W', type => 'yo', to => 'X'});
        my $map2 = $model->add_map({name => 'baz', description => 'quux'});
        $model->add_connection($map2, {from => 'WM', type => 'and', to => 'Y'});
        $model->add_connection($map2, {from => 'M', type => 'to', to => 'W'});

        like $model->get_map_tgf($map1), qr/^
            1 \  W \R
            2 \  X \R
            3 \  Y \R
            \# \R
            1 \  2 \  yo  \R
            2 \  3 \  and \R
        $/x, 'Correct TGF representation of first map';

        like $model->get_map_tgf($map2), qr/^
            1 \  M  \R
            2 \  W  \R
            3 \  WM \R
            4 \  Y  \R
            \# \R
            1 \  2 \  to  \R
            3 \  4 \  and \R
        $/x, 'Correct TGF representation of second map';
    };

    subtest 'Import' => sub {

        subtest 'From string' => sub {

            # Create and check creation ID
            my $map_id = $model->add_map_from_tgf('foo', 'bar',
                "1 X\n2 Y\n#\n1 2 a\n2 1 b\n"
            );
            ok defined($map_id), 'Generated ID is defined';
            like $map_id => qr/^\d+$/, 'Generated ID is a number';

            # Check its data
            my $map = $model->get_map_data($map_id);
            is_deeply $map => {id => $map_id,
                name        => 'foo',
                description => 'bar',
                connections => {
                    0 => {map => $map_id, id => 0,
                        from => 'X', to => 'Y', type => 'a',
                    },
                    1 => {map => $map_id, id => 1,
                        from => 'Y', to => 'X', type => 'b',
                    },
                },
            }, 'Correct map created from TGF';
        };

        subtest 'From file' => sub {

            # Prepare test TGF file
            my $tmp_file = File::Temp->new;
            my $tmp_fn   = $tmp_file->filename;
            $tmp_file->print("1 A\n2 B\n#\n2 1 x\n1 2 y\n");
            $tmp_file->close;

            # Create from file
            my $map_id = $model->add_map_from_tgf_file('qux', 'quux', $tmp_fn);
            ok defined($map_id), 'Generated ID is defined';
            like $map_id => qr/^\d+$/, 'Generated ID is a number';

            # Check its data
            my $map = $model->get_map_data($map_id);
            is_deeply $map => {id => $map_id,
                name        => 'qux',
                description => 'quux',
                connections => {
                    0 => {map => $map_id, id => 0,
                        from => 'B', to => 'A', type => 'x',
                    },
                    1 => {map => $map_id, id => 1,
                        from => 'A', to => 'B', type => 'y',
                    },
                },
            }, 'Correct map created from TGF file';
        };
    };
};

subtest 'Non-emptiness' => sub {
    ok ! $model->is_empty, 'Model not empty anymore';
    ok 1 >= time - $model->last_update, 'There was an update';
};

done_testing;

__END__
