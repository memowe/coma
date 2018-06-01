#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use_ok 'Coma::Data';
my $model = Coma::Data->new;

# Global test data
my $map_id;

subtest 'Add map' => sub {
    $map_id = $model->add_map({name => 'foo', description => 'bar'});
    ok defined($map_id), 'Generated ID is defined';
    like $map_id => qr/^\d+$/, 'Generated ID is a number';
};

subtest 'Load map' => sub {
    my $data = $model->get_map_data($map_id);
    ok defined($data), 'Retrieved data is defined';
    is_deeply $data => {
        name        => 'foo',
        description => 'bar',
        id          => $map_id,
    }, 'Retrieved map data is correct';
};

# TODO

done_testing;

__END__
