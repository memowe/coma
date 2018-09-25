# coma: Commands

Coma commands are custom Mojolicious commands, so they are called like this:

    $ ./coma dump -e
    [MapAdded (2018-07-20T15:47:29.53569) | description: '', id: '0', name: 'Beispiel']
    [...]

This document has information regarding the custom coma commands only. To learn more about the other (mojolicious) commands, have a look at the [Mojolicious::Commands][mocom] documentation.

[mocom]: https://mojolicious.org/perldoc/Mojolicious/Commands

## Command line documentation

To see which commands (mojo(licious) and custom) are available or get more information about them, you can also use the command system:

**Overview**

    $ ./coma help
    Usage: APPLICATION COMMAND [OPTIONS]
    [...]
    Commands:
        [...]
        daemon      Start application with HTTP and WebSocket server
        dump        Inspect the data model's events or state
        eval        Run code against application
        [...]
    See 'APPLICATION help COMMAND' for more information on a specific command.

**Command help**

    $ ./coma help dump
    Usage: coma dump [OPTIONS] [TIME]

        ./coma dump
        ./coma dump -s 1997-12-24T17:42:02Z
    [...]

## Data model inspection with the `dump` command

    Usage: coma dump [OPTIONS] [TIME]

As the database was dropped as a data model for coma in favor of a simple [event store][est], the state of the system can be inspected from two different perspectives:

- By using the `-e` option, the `dump` command lists all events that led to the current state.
- By using the `-d` option (default), the state of the system is dumped as a data structure text representation.

See the command's documentation for details.

[est]: https://metacpan.org/pod/EventStore::Tiny

## Using the [<abbr title="Trivial Graph Format">TGF</abbr>][wiki-tgf] format to exchange maps

This is almost self explanatory with these examples:

    $ ./coma import_tgf --name "Cool map" foo/bar/cool_map.tgf

<span></span>

    $ ./coma export_tgf --dir export/directory

<span></span>

    $ ./coma export_tgf --id 42

See the command's documentation for details.

[wiki-tgf]: https://en.wikipedia.org/wiki/Trivial_Graph_Format
