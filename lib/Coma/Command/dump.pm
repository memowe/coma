package Coma::Command::dump;
use Mojo::Base 'Mojolicious::Command', -signatures;

use Mojo::Util 'getopt';
use Time::HiRes 'time';
use DateTime::Format::ISO8601;
use Data::Dump;

has description => "Inspect the data model's events or state";
has usage       => <<USAGE;
Usage: coma dump [OPTIONS] [TIME]

    ./coma dump
    ./coma dump -s 1997-12-24T17:42:02Z
    ./coma dump --events 1533129357

Options:
    -s, --state     Dumps the state of the system.
    -e, --events    Dumps the list of events.
    -v, --verbose   Dumps events as perl objects in event mode.
    You can't use the options -s and -e  at the same time. Default: -s.

Time argument:
    The optional time argument defines for which time the events or current
    state of the system should be dumped. It can be given as a unix timestamp
    or a ISO8601 time string in the YYYY-MM-DDTHH:MM:SZ format.
    Default: the current time

USAGE

sub _extract_timestamp ($self, @args) {

    # Nothing given: use current time stamp
    return time unless @args;

    # Extract first argument
    my $time_arg = shift @args;

    # Looks like a number: should be a time stamp
    return $time_arg if $time_arg =~ /^\d+$/;

    # Else: try to use it as an input to ISO8601
    my $time = eval {DateTime::Format::ISO8601->parse_datetime($time_arg)};
    die "Invalid date: '$time_arg'\n" if $@ =~ /Invalid date format/;
    return $time->epoch;
}

sub run ($self, @args) {

    # Extract options (and use $events only from here)
    getopt \@args,
        's|state'   => \my $_state,
        'e|events'  => \my $events,
        'v|verbose' => \my $verbose;
    die $self->usage if $_state and $events;

    # Extract time
    my $time = $self->_extract_timestamp(@args);

    # Disable logging
    $self->app->data->logger(undef);

    # User wants to see events dumped?
    if ($events) {

        # Dig deep to extract event stream for the given time
        my $es = $self->app->data->events->_est->events->before($time);

        # Verbose? Dump them as perl objects
        if ($verbose) {
            dd @{$es->events};
        }

        # Non-verbose? Dump their summaries
        else {
            say $_->summary for @{$es->events};
        }
    }

    # Default: dump state
    else {
        dd $self->app->data->events->state($time);
    }
}

1;
__END__
