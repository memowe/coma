#!/usr/bin/env perl

use Mojolicious::Lite;
use Mojo::Util 'trim';
use Text::Markdown 'markdown';
use Graph::Centrality::Pagerank;

use lib app->home->rel_dir('lib');
use ComaDB;

# signed cookies passphrase (not used ATM)
app->secrets(['coma sowphen']);

# prepare database access
my $dbfile = $ENV{COMA_DB} // app->home->rel_file('data/graph.sqlite');
my $schema = ComaDB->connect("dbi:SQLite:$dbfile", '', '', {
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

# pagerank helper: expects LoL of vertex names
my $pr = Graph::Centrality::Pagerank->new();
helper calculate_pagerank => sub {
    my ($c, @graph) = @_;
    return $pr->getPagerankOfNodes(listOfEdges => \@graph);
};

# JSON entity completion
any '/entity_completion' => sub {
    my $c   = shift;
    my $str = $c->param('term') // 'xnorfzt';

    # find matching entities
    my $entities = $c->db('Entity')->search({
        name => {like => "%$str%"},
    });

    # render as json
    $c->render(json => [$entities->get_column('name')->all]);
};

# JSON connection completion
any '/connection_completion' => sub {
    my $c   = shift;
    my $str = $c->param('term') // 'xnorfzt';

    # find matching connections
    my $ctypes = $c->db('ConnectionType')->search({
        name => {like => "%$str%"},
    });

    # render as json
    $c->render(json => [$ctypes->get_column('name')->all]);
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

    # load entities (including degree)
    my $entities = $c->db('Entity');

    # calculate reverse pagerank
    my $pagerank = $c->calculate_pagerank(
        map [$_->to_name => $_->from_name] => $c->db('Connection')->all
    );

    # done
    $c->stash(
        entities    => $entities,
        pagerank    => $pagerank,
    );
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
    my $from_deg = $entity->from_degrees->get_column('from_degree')->sum // 0;
    my $to_deg   = $entity->to_degrees->get_column('to_degree')->sum // 0;

    # get neighbourhood
    my $from_ent = $entity->from_connections->search_related('to_entity',
        undef, {distinct => 1}
    );
    my $to_ent   = $entity->to_connections->search_related('from_entity',
        undef, {distinct => 1}
    );

    # calculate reverse pagerank
    my $pagerank = $c->calculate_pagerank(
        map [$_->to_name => $_->from_name] => $c->db('Connection')->all
    );

    # find all maps with this entity
    my $maps = $entity->maps->search(undef, {distinct => 1});

    # done
    $c->stash(
        degree          => $degree,
        from_degree     => $from_deg,
        to_degree       => $to_deg,
        from_neighbours => $from_ent,
        to_neighbours   => $to_ent,
        pagerank        => $pagerank,
        maps            => $maps,
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
    my $entities = $map->map_entities;

    # calculate reverse pagerank
    my $pagerank = $c->calculate_pagerank(
        map [$_->to_name => $_->from_name] => $map->connections->all
    );

    # done
    $c->stash(
        entities => $entities,
        pagerank => $pagerank,
    );
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
    my $map = $c->stash('map');
    $map->delete_related('connections');
    $map->delete;

    # done
    $c->redirect_to('home');
} => 'delete_map_sure';

# tgf export of one map
app->types->type(tgf => 'text/plain;charset=UTF-8');
get '/tgf_export' => sub {
    my $c = shift;
    
    # force download
    my $fn = $c->stash('map')->name . '.tgf';
    $c->res->headers->content_disposition("attachment; filename=$fn");

    # render tgf template
    $c->render(format => 'tgf');
};

app->start;
