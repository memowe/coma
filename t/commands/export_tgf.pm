#!/usr/bin/env perl

use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Exception;
use Test::Mojo;
use Mojo::File 'path';
use File::Temp qw(tmpnam tempdir);
use FindBin '$Bin';

# Prepare an empty coma app
$ENV{COMA_DATA_FILE} = tmpnam;
$ENV{COMA_INIT_DIR}  = tempdir;
require "$Bin/../../coma";
my $t = Test::Mojo->new;

# Disable logging
$t->app->data->logger(undef);

# Define a test helper to capture command outputs
sub test_output ($args, $test_cb, $test_name = 'Output test') {
    subtest $test_name => sub {

        # Capture output into temp file
        my $tmpf    = File::Temp->new;
        my $tmpfn   = $tmpf->filename;
        select $tmpf;
        lives_ok sub {$t->app->start(export_tgf => @$args)},
            "Command didn't die";
        select STDOUT;
        close $tmpf;

        # Slurp output (overwrite $tmpf by simple file handle)
        open $tmpf, '<', $tmpfn
            or die "Couldn't open temp file '$tmpfn': $!\n";
        my $output = do {local $/; <$tmpf>}; # Standard idiom
        close $tmpf;

        # Execute tests on output
        subtest 'Handle command output' => sub {
            $test_cb->($output)
        };
    };
}

# Insert example data
my $map1_id = $t->app->data->add_map({name => 'foo', description => 'bar'});
my $con1_id = $t->app->data->add_connection($map1_id, {
    from    => 'baz',
    type    => 'quux',
    to      => 'quuux',
});
my $map2_id = $t->app->data->add_map({name => 'xno', description => 'rfzt'});
my $con2_id = $t->app->data->add_connection($map2_id, {
    from    => 'yada',
    type    => 'yoda',
    to      => 'yolo',
});

# Firing the default configuration of the command
test_output [] => sub ($output) {

    # Check output
    my $output_rx = qr/
        Export \s directory \s is \s '([^']+)'\. \R
        Map \s foo \s \(ID \s $map1_id\) \s -> \s (.*) \R
        Map \s xno \s \(ID \s $map2_id\) \s -> \s (.*) \R
        Done\. \R
    /x;
    like $output => $output_rx, 'Output has all the information';

    # Extract data
    $output =~ $output_rx;
    my ($dir, $map1_fn, $map2_fn) = ($1, $2, $3);

    # Check output file structure
    my $export_dir = $t->app->home->rel_file('export');
    like $dir => qr/^$export_dir/, 'Export dir starts correctly';
    my %fn = map {path($_)->basename('.tgf') => $_} <$dir/*>;
    is_deeply \%fn => {"foo_$map1_id" => $map1_fn, xno_1 => $map2_fn},
        'Correct file names';

    # Check output file content
    is path($fn{"foo_$map1_id"})->slurp =>
        $t->app->data->get_map_tgf($map1_id), 'Correct tgf for map 1';
    is path($fn{"xno_$map2_id"})->slurp =>
        $t->app->data->get_map_tgf($map2_id), 'Correct tgf for map 2';

    # Cleanup
    path($dir)->remove_tree;
}, 'No options given';

# Firing with a given map ID that doesn't exist
test_output [-i => 42] => sub ($output) {

    # Check output
    my $output_rx = qr/
        Export \s directory \s is \s '([^']+)'\. \R
        Unknown \s map: \s 42 \R
        Nothing \s to \s export\. \s
            Deleting \s export \s directory\. \R
    /x;
    like $output => $output_rx, 'Correct output';
    $output =~ $output_rx;
    ok not(-e $1), "Directory doesn't exist";
}, "ID given that doesn't exist";

# Firing with a given map ID
test_output [-i => $map2_id] => sub ($output) {

    # Check output
    my $output_rx = qr/
        Export \s directory \s is \s '([^']+)'\. \R
        Map \s xno \s \(ID \s $map2_id\) \s -> \s (.*) \R
        Done\. \R
    /x;
    like $output => $output_rx, 'Output has all the information';

    # Extract data
    $output =~ $output_rx;
    my ($dir, $map2_fn) = ($1, $2);

    # Check output file structure
    my $export_dir = $t->app->home->rel_file('export');
    like $dir => qr/^$export_dir/, 'Export dir starts correctly';
    my %fn = map {path($_)->basename('.tgf') => $_} <$dir/*>;
    is_deeply \%fn => {"xno_$map2_id" => $map2_fn}, 'Correct file name';

    # Check output file content
    is path($fn{"xno_$map2_id"})->slurp =>
        $t->app->data->get_map_tgf($map2_id), 'Correct tgf for map 2';

    # Cleanup
    path($dir)->remove_tree;
}, 'ID given';

# Firing with a given directory that doesn't exist
my $tmp_dn = tmpnam; # Temporary name, no file creation
ok not(-d $tmp_dn), "Directory currently doesn't exist";
test_output [-i => $map2_id, -d => $tmp_dn] => sub ($output) {

    # Check output
    my $output_rx = qr/
        Export \s directory \s is \s '([^']+)'\. \R
        Map \s xno \s \(ID \s $map2_id\) \s -> \s (.*) \R
        Done\. \R
    /x;
    like $output => $output_rx, 'Output has all the information';

    # Extract data
    $output =~ $output_rx;
    my ($dir, $map2_fn) = ($1, $2);

    # Check output file structure
    is $dir => $tmp_dn, 'Correct export directory';
    ok -d $dir, 'Export directory exists';
    my %fn = map {path($_)->basename('.tgf') => $_} <$dir/*>;
    is_deeply \%fn => {"xno_$map2_id" => $map2_fn}, 'Correct file name';

    # Check output file content
    is path($fn{"xno_$map2_id"})->slurp =>
        $t->app->data->get_map_tgf($map2_id), 'Correct tgf for map 2';

    # Cleanup
    path($dir)->remove_tree;
}, 'Export directory given (non-existant)';

# Firing with a given directory that already exists
my $tmp_d = tempdir; # Temporary name, no file creation
ok -d $tmp_d, 'Directory already exists';
test_output [-i => $map1_id, -d => $tmp_d] => sub ($output) {

    # Check output
    my $output_rx = qr/
        Export \s directory \s is \s '([^']+)'\. \R
        Map \s foo \s \(ID \s $map1_id\) \s -> \s (.*) \R
        Done\. \R
    /x;
    like $output => $output_rx, 'Output has all the information';

    # Extract data
    $output =~ $output_rx;
    my ($dir, $map1_fn) = ($1, $2);

    # Check output file structure
    is $dir => $tmp_d, 'Correct export directory';
    ok -d $dir, 'Export directory exists';
    my %fn = map {path($_)->basename('.tgf') => $_} <$dir/*>;
    is_deeply \%fn => {"foo_$map1_id" => $map1_fn}, 'Correct file name';

    # Check output file content
    is path($fn{"foo_$map1_id"})->slurp =>
        $t->app->data->get_map_tgf($map1_id), 'Correct tgf for map 1';

    # Cleanup
    path($dir)->remove_tree;
}, 'Export directory given';

done_testing;

__END__
