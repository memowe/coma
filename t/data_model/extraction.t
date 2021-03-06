#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use_ok 'Coma::Data';
my $model = Coma::Data->new;

# Disable event logging for tests as events are tested in EventStore::Tiny
$model->logger(undef);

# Preparation
my $map1 = $model->add_map({name => 'foo', description => 'bar'});
$model->add_connection($map1, {from => 'X', type => 'and', to => 'Y'});
$model->add_connection($map1, {from => 'WTF', type => 'yo', to => 'X'});
my $map2 = $model->add_map({name => 'baz', description => 'quux'});
$model->add_connection($map2, {from => 'WTF', type => 'and', to => 'Y'});
$model->add_connection($map2, {from => 'M', type => 'to', to => 'W'});

subtest 'Entity map filter' => sub {

    is_deeply $model->get_map_ids_with_entity('YOLO') => [],
        'No maps found for entity "YOLO"';
    is_deeply $model->get_map_ids_with_entity('W') => [$map2],
        'One map found for entity "W"';
    is_deeply $model->get_map_ids_with_entity('Y') => [$map1, $map2],
        'Two maps found for entity "Y"';
};

subtest 'Entity listing' => sub {

    subtest 'Per map' => sub {
        is_deeply $model->get_entities($map1) => [qw(WTF X Y)],
            'Correct first map entities';
        is_deeply $model->get_entities($map2) => [qw(M W WTF Y)],
            'Correct second map entities';
        ok ! $model->has_entity('W', $map1),
            'Entity W not found in first map';
        ok $model->has_entity('W', $map2),
            'Entity W found in the second map';
    };

    subtest 'Across all maps' => sub {
        is_deeply $model->get_entities => [qw(M W WTF X Y)],
            'Correct entities';
        ok ! $model->has_entity('Z'),
            'Entity Z not found in a map';
        ok $model->has_entity('W'),
            'Entity W found in a map';
    };
};

subtest 'Entity degrees' => sub {

    subtest 'Indegree' => sub {

        subtest 'Per map' => sub {
            is_deeply $model->get_entity_indegrees($map1) => {
                X => 1, Y => 1,
            }, 'Correct first map indegree entities';
            is_deeply $model->get_entity_indegrees($map2) => {
                W => 1, Y => 1,
            }, 'Correct second map indegree entities';
        };

        subtest 'Global' => sub {
            is_deeply $model->get_entity_indegrees => {
                W => 1, X => 1, Y => 2,
            }, 'Correct indegree entities';
        };
    };

    subtest 'Outdegree' => sub {
        subtest 'Per map' => sub {
            is_deeply $model->get_entity_outdegrees($map1) => {
                WTF => 1, X => 1,
            }, 'Correct first map outdegree entities';
            is_deeply $model->get_entity_outdegrees($map2) => {
                M => 1, WTF => 1,
            }, 'Correct second map outdegree entities';
        };

        subtest 'Global' => sub {
            is_deeply $model->get_entity_outdegrees => {
                M => 1, WTF => 2, X => 1,
            }, 'Correct outdegree entities';
        };
    };

    subtest 'Combined' => sub {

        subtest 'Per map' => sub {
            is_deeply $model->get_entity_degrees($map1) => {
                WTF => 1, X => 2, Y => 1,
            }, 'Correct first map entities';
            is_deeply $model->get_entity_degrees($map2) => {
                M => 1, W => 1, WTF => 1, Y => 1,
            }, 'Correct second map entities';
        };

        subtest 'Across all maps' => sub {
            is_deeply $model->get_entity_degrees => {
                M => 1, W => 1, WTF => 2, X => 2, Y => 2,
            }, 'Correct entities';
        };
    };
};

subtest 'Connections' => sub {

    subtest 'Per map' => sub {
        is_deeply $model->get_connections($map1) => [
            {from => 'WTF', type => 'yo',  to => 'X'},
            {from => 'X',   type => 'and', to => 'Y'},
        ], 'Correct connections from map 1';
        is_deeply $model->get_connections($map2) => [
            {from => 'M',   type => 'to',  to => 'W'},
            {from => 'WTF', type => 'and', to => 'Y'},
        ], 'Correct connections from map 2';
    };

    subtest 'Global' => sub {
        is_deeply $model->get_connections => [
            {from => 'M',   type => 'to',  to => 'W'},
            {from => 'WTF', type => 'yo',  to => 'X'},
            {from => 'WTF', type => 'and', to => 'Y'},
            {from => 'X',   type => 'and', to => 'Y'},
        ], 'Correct connections';
    };
};


subtest 'Connection types' => sub {

    subtest 'Per map' => sub {
        is_deeply $model->get_connection_types($map1) => {
            and => 1, yo => 1,
        }, 'Correct types and occurrences';
        is_deeply $model->get_connection_types($map2) => {
            and => 1, to => 1,
        }, 'Correct types and occurrences';
    };

    subtest 'Global' => sub {
        is_deeply $model->get_connection_types => {
            and => 2, to => 1, yo => 1,
        }, 'Correct types and occurrences';
    };
};

subtest 'Connection pairs' => sub {

    subtest 'Per map' => sub {
        is_deeply $model->get_connection_pairs($map1) => [
            [WTF => 'X'], [X => 'Y'],
        ], 'Correct pairs for map 1';
        is_deeply $model->get_connection_pairs($map2) => [
            [M => 'W'], [WTF => 'Y'],
        ], 'Correct pairs for map 2';
    };

    subtest 'Global' => sub {
        is_deeply $model->get_connection_pairs => [
            [M => 'W'], [WTF => 'X'], [WTF => 'Y'], [X => 'Y'],
        ], 'Correct pairs for map 2';
    };
};

subtest 'Neighbourhood' => sub {

    subtest 'Combined' => sub {
        is_deeply $model->get_neighbourhood('X', $map1), [qw(WTF Y)],
            'Correct neighbourhood of X in first map';
        is_deeply $model->get_neighbourhood('X'), [qw(WTF Y)],
            'Correct neighbourhood of X in all maps';
    };

    subtest 'Incoming' => sub {
        is_deeply $model->get_incoming_neighbourhood('Y', $map1), [qw(X)],
            'Correct incoming neighbourhood of Y in first map';
        is_deeply $model->get_incoming_neighbourhood('Y'), [qw(WTF X)],
            'Correct incoming neighbourhood of Y in all maps';
    };

    subtest 'Outgoing' => sub {
        is_deeply $model->get_outgoing_neighbourhood('WTF', $map1), [qw(X)],
            'Correct outgoing neighbourhood of WTF in first map';
        is_deeply $model->get_outgoing_neighbourhood('WTF'), [qw(X Y)],
            'Correct outgoing neighbourhood of WTF in all maps';
    };
};

done_testing;

__END__
