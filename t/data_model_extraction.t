#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use_ok 'Coma::Data';
my $model = Coma::Data->new;

# Disable event logging for tests as events are tested in EventStore::Tiny
$model->events->_est->logger(undef);

# Preparation
my $map1 = $model->add_map({name => 'foo', description => 'bar'});
$model->add_connection($map1, {from => 'X', type => 'and', to => 'Y'});
$model->add_connection($map1, {from => 'WTF', type => 'yo', to => 'X'});
my $map2 = $model->add_map({name => 'baz', description => 'quux'});
$model->add_connection($map2, {from => 'WTF', type => 'and', to => 'Y'});
$model->add_connection($map2, {from => 'M', type => 'to', to => 'W'});

subtest 'Entity listing' => sub {

    subtest 'Per map' => sub {
        is_deeply $model->get_entities($map1) => [qw(WTF X Y)],
            'Correct first map entities';
        is_deeply $model->get_entities($map2) => [qw(M W WTF Y)],
            'Correct second map entities';
    };

    subtest 'Across all maps' => sub {
        is_deeply $model->get_entities => [qw(M W WTF X Y)],
            'Correct entities';
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

done_testing;

__END__