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

done_testing;

__END__
