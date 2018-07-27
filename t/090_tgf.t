#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojo::Base -base, -signatures;
use File::Temp qw(tempdir tempfile);
use FindBin '$Bin';

# prepare some TGF data
my $tgf_data = <<'TGF2';
1 bar
2 baz
3 foo
#
1 2 quux
2 3 quuux
TGF2

# make sure there's no matching map
my $map_links = $t->get_ok('/')->tx->res->dom('a[href^=/map/]');
my $test_map_links = $map_links->grep(sub ($l) { $l->text =~ /^test_/ });
is $test_map_links->size, 0, 'no test map';

# prepare a temporary TGF file
my ($temp_fh, $temp_fn) = tempfile('test_XXXXX',
    DIR     => tempdir(CLEANUP => 1),
    SUFFIX  => '.tgf',
);
print $temp_fh $tgf_data;

# import
my $output = `COMA_DB=$ENV{COMA_DB} echo "$temp_fn" | perl $Bin/../script/import_tgf_files.pl`;
like $output, qr/3 concepts and 2 links \(0 duplicates\)/, 'right output';

# find this map
$map_links = $t->get_ok('/')->tx->res->dom('a[href^=/map/]');
$test_map_links = $map_links->grep(sub ($l) { $l->text =~ /^test_/ });
is $test_map_links->size, 1, 'imported something';

# export its TGF
$t->get_ok($test_map_links->first->attr('href') . "/tgf_export");
$t->content_is($tgf_data);

done_testing;
