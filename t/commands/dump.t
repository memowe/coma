#!/usr/bin/env perl

use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Exception;
use Test::Mojo;
use File::Temp qw(tmpnam tempdir);
use Clone 'clone';
use FindBin '$Bin';

# Prepare an empty coma app
$ENV{COMA_DATA_FILE} = tmpnam;
$ENV{COMA_INIT_DIR}  = tempdir;
require "$Bin/../../coma";
my $t = Test::Mojo->new;

# Insert example data
my $map_id = $t->app->data->add_map({name => 'foo', description => 'bar'});
my $con_id = $t->app->data->add_connection($map_id, {
    from    => 'baz',
    type    => 'quux',
    to      => 'quuux',
});

# Define a test helper to capture dump command outputs
sub test_output ($args, $test_cb, $test_name = 'Output test') {
    subtest $test_name => sub {

        # Capture output into temp file
        my $tmpf = File::Temp->new;
        select $tmpf;
        lives_ok sub {$t->app->start(dump => @$args)}, "Command didn't die";
        select STDOUT;
        close $tmpf;

        # Slurp output (overwrite $tmpf by simple file handle)
        open $tmpf, '<', $tmpf->filename
            or die "Couldn't open temp file: $!\n";
        my $output = do {local $/; <$tmpf>}; # Standard idiom
        close $tmpf;

        # Execute tests on output
        subtest 'Handle command output' => sub {
            $test_cb->($output)
        };
    };
}

subtest 'Error handling' => sub {

    # Invalid date
    throws_ok sub {
        $t->app->start('dump', 'invalid');
    }, qr/^Invalid date: 'invalid'$/, 'Correct error message for invalid date';

    # Contradicting options
    throws_ok sub {
        $t->app->start('dump', '-s', '-e')
    }, qr/^Usage/, 'Correct error message for contradicting options';
};

subtest 'Dumping state of the system' => sub {

    # No time given
    my $state_output;
    test_output ['-s'] => sub ($output) {

        # Keep the state output for later default test
        $state_output = $output;

        # Eval output as a Perl data structure
        my $data;
        lives_ok sub {$data = eval $output}, "Output can be eval'ed";

        # Check the state for correctness
        is_deeply $data => {maps => {0 => {
            id          => 0,
            name        => 'foo',
            description => 'bar',
            connections => {0 => {
                id      => 0,
                map     => 0,
                from    => 'baz',
                type    => 'quux',
                to      => 'quuux',
            }},
        }}}, 'Correct state';
    }, 'No time argument';

    subtest 'Time in the past' => sub {
        my $empty_output;

        # Timestamp
        test_output ['-s', 42] => sub ($output) {
            $empty_output = $output;
            like $output => qr/^ { } $/x, 'Correct empty output';
        }, 'Timestamp';

        # ISO8601
        test_output ['-s', '1970-11-23T09:11:42'] => sub ($output) {
            is $output => $empty_output, 'Same output';
        }, 'ISO8601';
    };

    subtest 'Time in the future' => sub {
        my $future_output;

        # Timestamp
        test_output ['-s', time + 42] => sub ($output) {
            $future_output = $output;

            # Eval output as a Perl data structure
            my $data;
            lives_ok sub {$data = eval $output}, "Output can be eval'ed";

            # Check the state for correctness
            is_deeply $data => {maps => {0 => {
                id          => 0,
                name        => 'foo',
                description => 'bar',
                connections => {0 => {
                    id      => 0,
                    map     => 0,
                    from    => 'baz',
                    type    => 'quux',
                    to      => 'quuux',
                }},
            }}}, 'Correct state';
        }, 'Timestamp';

        # ISO8601
        test_output ['-s', '2142-11-23T09:11:42'] => sub ($output) {
            is $output => $future_output, 'Same output';
        }, 'ISO8601';
    };

    # State is the default
    test_output [] => sub ($output) {
        is $output => $state_output, 'Same output';
    }, 'State is the default';
};

subtest 'Dumping summarized event log of the system' => sub {

    # No time given
    test_output ['-e'] => sub ($output) {
        my @lines       = split $/ => $output;
        my @summaries   = map $_->summary =>
            @{$t->app->data->events->_est->events->events};
        is_deeply \@lines => \@summaries, 'Correct event log';
    }, 'No time argument';

    subtest 'Time in the past' => sub {

        # Timestamp
        test_output ['-e', 42] => sub ($output) {
            is $output => '', 'Correct empty output';
        }, 'Timestamp';

        # ISO8601
        test_output ['-e', '1970-11-23T09:11:42'] => sub ($output) {
            is $output => '', 'Same output';
        }, 'ISO8601';
    };

    subtest 'Time in the future' => sub {
        my $future_output;

        # Timestamp
        test_output ['-e', time + 42] => sub ($output) {
            $future_output  = $output;
            my @lines       = split $/ => $output;
            my @summaries   = map $_->summary =>
                @{$t->app->data->events->_est->events->events};
            is_deeply \@lines => \@summaries, 'Correct event log';
        }, 'Timestamp';

        # ISO8601
        test_output ['-e', '2142-11-23T09:11:42'] => sub ($output) {
            is $output => $future_output, 'Same output';
        }, 'ISO8601';
    };
};

subtest 'Dumping verbose event log of the system' => sub {

    # No time given
    test_output ['-e', '-v'] => sub ($output) {

        # Eval output as a Perl data structure
        my @events;
        lives_ok sub {@events = eval $output}, "Output can be eval'ed";

        # Copy the current event log
        my $event_log = clone $t->app->data->events->_est->events->events;

        # Don't look at transformations as they can't be compared
        delete $_->{transformation} for @$event_log, @events;
        is_deeply \@events, $event_log, 'Correct event log';
    }, 'No time argument';

    subtest 'Time in the past' => sub {
        my $empty_output;

        # Timestamp
        test_output ['-e', '-v', 42] => sub ($output) {
            $empty_output = $output;
            like $output => qr/^ \( \) $/x, 'Correct empty output';
        }, 'Timestamp';

        # ISO8601
        test_output ['-e', '-v', '1970-11-23T09:11:42'] => sub ($output) {
            is $output => $empty_output, 'Same output';
        }, 'ISO8601';
    };

    subtest 'Time in the future' => sub {
        my $future_output;

        # Timestamp
        test_output ['-e', '-v', time + 42] => sub ($output) {
            $future_output = $output;

            # Eval output as a Perl data structure
            my @events;
            lives_ok sub {@events = eval $output}, "Output can be eval'ed";

            # Copy the current event log
            my $event_log = clone $t->app->data->events->_est->events->events;

            # Don't look at transformations as they can't be compared
            delete $_->{transformation} for @$event_log, @events;
            is_deeply \@events, $event_log, 'Correct event log';
        }, 'Timestamp';

        # ISO8601
        test_output ['-e', '-v', '2142-11-23T09:11:42'] => sub ($output) {
            is $output => $future_output, 'Same output';
        }, 'ISO8601';
    };
};

done_testing;

__END__
