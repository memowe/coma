#!/usr/bin/env perl

# prepare db schema auto loading
$ENV{SCHEMA_LOADER_BACKCOMPAT} = 1;
package Coma::DB;
use base 'DBIx::Class::Schema::Loader';

# lite app
package main;

use Mojolicious::Lite;
use Mojo::Util 'trim';
use Text::Markdown 'markdown';

# prepare database access
my $dbfile = $ENV{COMA_DB} // app->home->rel_file('data/graph.sqlite');
my $schema = Coma::DB->connect("dbi:SQLite:dbname=$dbfile", '', '', {
    AutoCommit      => 1,
    RaiseError      => 1,
    sqlite_unicode  => 1,
});

# database helper, with argument: that resultset, else: the schema
helper db => sub {
    my ($c, $rs) = @_;
    return $rs ? $schema->resultset($rs) : $schema;
};

# markdown helper
helper markdown => sub {
    my ($c, $text) = @_;
    return markdown $text;
};

# JSON entity completion
any '/entity_completion' => sub {
    my $c   = shift;
    my $str = $c->param('term') // 'xnorfzt';

    # find matching entities
    my @entities = $c->db('Entity')->search({
        name => {like => "%$str%"},
    })->all;

    # render as json
    $c->render(json => [map $_->name => @entities]);
};

# JSON connection completion
any '/connection_completion' => sub {
    my $c   = shift;
    my $str = $c->param('term') // 'xnorfzt';

    # find matching connections
    my @ctypes = $c->db('ConnectionType')->search({
        name => {like => "%$str%"},
    })->all;

    # render as json
    $c->render(json => [map $_->name => @ctypes]);
};

# home: show all maps 'n' stuff
get '/' => sub {
    my $c = shift;
    $c->stash(maps => $c->db('Map'));
} => 'home';

# add a map
post '/' => sub {
    my $c = shift;

    # create the map
    my $map = $c->db('Map')->create({
        name        => $c->param('name'),
        description => $c->param('description'),
    });

    # done
    $c->redirect_to('show_map', map_id => $map->id);
} => 'add_map';

# show entity cloud
get '/entities' => sub {
    my $c = shift;
    $c->stash(entities => $c->db('Entity'));
} => 'entities';

# show entity data
get '/entity/:entity_name' => sub {
    my $c   = shift;
    my $en  = $c->param('entity_name');

    # try to retrieve entity
    my $entity = $c->db('Entity')->search({name => $en})->first;
    return $c->render_not_found unless $entity;

    # get degree
    my $degree = $entity->degree;

    # get directed degrees
    my $fd = $c->db('FromDegree')->search({name => $en})->first;
    my $td = $c->db('ToDegree')->search({name => $en})->first;
    my $from_degree = $fd ? $fd->from_degree : 0;
    my $to_degree   = $td ? $td->to_degree : 0;

    # done
    $c->stash(
        degree      => $degree,
        from_degree => $from_degree,
        to_degree   => $to_degree,
    );
} => 'show_entity';

# under here: work on one map
under '/map/:map_id' => [map_id => qr/\d+/] => sub {
    my $c = shift;

    # try to load map
    my $map = $c->db('Map')->find($c->param('map_id'), {
        prefetch => 'connections',
        order_by => [qw(connections.from_name connections.to_name)],
    });
    $c->render_not_found and return unless $map;

    # ok, we have a map
    $c->stash(map => $map);
    return 1;
};

# show one map
get '/' => sub {
    my $c   = shift;
    my $map = $c->stash('map');

    # load entities of this map
    my $entities = $c->db('MapEntity')->search({map_id => $map->id});

    # done
    $c->stash(entities => $entities);
} => 'show_map';

# edit map meta data
post '/edit' => sub {
    my $c   = shift;
    my $map = $c->stash('map');

    # update map meta data
    $map->update({
        name        => $c->param('name'),
        description => $c->param('description'),
    });

    # done
    $c->redirect_to('show_map');
} => 'edit_map';

# add a connection
post '/' => sub {
    my $c   = shift;
    my $map = $c->stash('map');

    # insert a new connection for this map
    $map->create_related('connections', {
        from_name   => trim($c->param('from')),
        type        => trim($c->param('type')),
        to_name     => trim($c->param('to')),
    });

    # done
    $c->redirect_to('show_map');
} => 'add_connection';

# delete a connection
post '/delete_connection' => sub {
    my $c   = shift;
    my $map = $c->stash('map');

    # delete all matching connections (<= 1)
    $map->delete_related('connections', {
        from_name   => $c->param('from'),
        type        => $c->param('type'),
        to_name     => $c->param('to'),
    });

    # done
    $c->redirect_to('show_map');
};

# delete a map
post '/delete' => 'delete_map';

# delete a map and the user is sure
post '/delete_sure' => sub {
    my $c = shift;

    # delete it
    $c->stash('map')->delete;

    # done
    $c->redirect_to('home');
} => 'delete_map_sure';

app->start;
__END__
