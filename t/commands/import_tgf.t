#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Mojo;
use File::Temp qw(tmpnam tempdir);
use Mojo::File 'path';

use FindBin '$Bin';

# Create a temporary TGF file
my $tmp_fn  = tmpnam;
open my $tmp_fh, '>', $tmp_fn or die "Couldn't open '$tmp_fn': $!\n";
print $tmp_fh <<TGF;
1 Answer
2 42
#
1 2 is
TGF
close $tmp_fh; # Flush

# Fire the command into a fresh app without persistent or initial data
$ENV{COMA_DATA_FILE} = tmpnam;
$ENV{COMA_INIT_DIR}  = tempdir;
require "$Bin/../../coma";
my $t = Test::Mojo->new;
$t->app->start('import_tgf', '-d', 'foo bar baz', $tmp_fn);

# Read the map from data model
is_deeply $t->app->data->get_all_map_ids => [0], 'One map imported';
my $map_data = $t->app->data->get_map_data(0);
is_deeply $map_data => {
    name        => path($tmp_fn)->basename('.tgf'),
    description => 'foo bar baz',
    id          => 0,
    connections => {0 => {
        id      => 0,
        map     => 0,
        from    => 'Answer',
        type    => 'is',
        to      => '42',
    }},
}, 'Correct map data';

done_testing;

__END__
