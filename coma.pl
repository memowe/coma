#!/usr/bin/env perl

use Mojolicious::Lite;
use Mojo::Util 'trim';
use Text::Markdown 'markdown';

# prepare markdown
helper markdown => sub {
    my ($c, $text) = @_;
    return markdown $text;
};

# prepare database access
use ORLite {
    package     => 'Coma',
    file        => $ENV{COMA_DB} // app->home->rel_file('data/graph.sqlite'),
    unicode     => 1,
    create      => sub {
        my $dbh = shift;

        # create the table for maps
        $dbh->do('CREATE TABLE map (
            id          INTEGER PRIMARY KEY,
            name        STRING,
            description STRING
        );');

        # insert a sample map
        my $insert_map = $dbh->prepare('INSERT INTO map
            (name, description) VALUES (?, ?)
        ');
        $insert_map->execute('Beispiel', 'Eine **Beispiel-Concept-Map**');
        my $example_map_id = $dbh->last_insert_id((undef) x 4);

        # create the table for connections
        $dbh->do('CREATE TABLE connection (
            map_id      INTEGER,
            from_name   STRING,
            type        STRING,
            to_name     STRING,
            PRIMARY KEY (map_id, from_name, type, to_name),
            FOREIGN KEY (map_id) REFERENCES map (id)
        );');

        # insert some example connections
        my $insert_connection = $dbh->prepare('INSERT INTO connection
            (map_id, from_name, type, to_name) VALUES (?, ?, ?, ?)
        ');
        $insert_connection->execute(@$_) for @{[
            [$example_map_id, qw(Java isa Programmiersprache)],
            [$example_map_id, qw(Java has JVM)],
            [$example_map_id, qw(Programmiersprache isa JVM)],
        ]};
    },
};

# JSON entity completion
any '/entity_completion' => sub {
    my $c   = shift;
    my $str = $c->param('term') // 'xnorfzt';

    # find matching connections for both from and to part
    my @fromm   = Coma::Connection->select('WHERE from_name LIKE ?', "%$str%");
    my @tom     = Coma::Connection->select('WHERE to_name   LIKE ?', "%$str%");

    # unique entity names
    my %names = (
        (map {$_->from_name => 1} @fromm),
        (map {$_->to_name   => 1} @tom),
    );
    my @names = keys %names;

    # render as json
    $c->render(json => \@names);
};

# JSON connection completion
any '/connection_completion' => sub {
    my $c   = shift;
    my $str = $c->param('term') // 'xnorfzt';

    # find unique connection types (represented by any connection)
    my @connections = Coma::Connection->select(
        'WHERE type LIKE ? GROUP BY type', "%$str%"
    );

    # render as json
    $c->render(json => [map $_->type => @connections]);
};

# show all maps
get '/' => sub {
    my $c = shift;
    $c->stash(maps => [Coma::Map->select]);
} => 'list_maps';

# add a map
post '/' => sub {
    my $c = shift;

    # create the map
    my $map = Coma::Map->new(
        name        => $c->param('name'),
        description => $c->param('description'),
    )->insert;

    # done
    $c->redirect_to('show_map', map_id => $map->id);
} => 'add_map';

# under here: work on one map
under '/map/:map_id' => [map_id => qr/\d+/] => sub {
    my $c = shift;

    # try to load map
    my $map = eval { Coma::Map->load($c->param('map_id')) };
    $c->render_not_found and return if $@;

    # ok, we have a map
    $c->stash(map => $map);
    return 1;
};

# show one map
get '/' => sub {
    my $c   = shift;
    my $map = $c->stash('map');

    # load connections
    my @connections = Coma::Connection->select('where map_id = ?', $map->id);
    $c->stash(connections => \@connections);
} => 'show_map';

# add a connection
post '/' => sub {
    my $c = shift;

    # build and insert a new connection
    my $connection  = Coma::Connection->new(
        map_id      => $c->stash('map')->id,
        from_name   => trim($c->param('from')),
        type        => trim($c->param('type')),
        to_name     => trim($c->param('to')),
    )->insert;

    # done
    $c->redirect_to('show_map');
} => 'add_connection';

# delete a connection
post '/delete_connection' => sub {
    my $c   = shift;
    my $map = $c->stash('map');

    # delete all matching connections (<= 1)
    Coma::Connection->delete_where(
        'map_id = ? AND from_name = ? AND type = ? AND to_name = ?',
        $map->id, $c->param('from'), $c->param('type'), $c->param('to'),
    );

    # done
    $c->redirect_to('show_map', map_id => $map->id);
};

# delete a map
post '/delete' => 'delete_map';

# delete a map and the user is sure
post '/delete_sure' => sub {
    my $c = shift;

    # delete it
    $c->stash('map')->delete;

    # done
    $c->redirect_to('list_maps');
} => 'delete_map_sure';

app->start;
__END__
