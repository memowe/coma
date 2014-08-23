#!/usr/bin/env perl

use Mojolicious::Lite;

# prepare database access
use ORLite {
    package     => 'Coma',
    file        => $ENV{COMA_DB} // app->home->rel_file('data/graph.sqlite'),
    unicode     => 1,
    create      => sub {
        my $dbh = shift;

        # create the table for entities
        $dbh->do('CREATE TABLE entity (
            name STRING PRIMARY KEY
        );');

        # insert some example entities
        my $insert = $dbh->prepare('INSERT INTO entity (name) VALUES (?)');
        $insert->execute($_) for qw(Programmiersprache Java JVM);

        # create the table for connections
        $dbh->do('CREATE TABLE connection (
            from_name   STRING,
            type        STRING,
            to_name     STRING,
            PRIMARY KEY (from_name, to_name, type),
            FOREIGN KEY (from_name) REFERENCES entity (name),
            FOREIGN KEY (to_name) REFERENCES entity (name)
        );');

        # insert some example connections
        $insert = $dbh->prepare('INSERT INTO connection
            (from_name, type, to_name) VALUES (?, ?, ?)
        ');
        $insert->execute(@$_) for @{[
            [qw(Java isa Programmiersprache)],
            [qw(Java has JVM)],
            [qw(Programmiersprache isa JVM)],
        ]};
    },
};

get '/' => 'index';

# JSON entity completion
any '/entity_completion' => sub {
    my $c   = shift;
    my $str = $c->param('term') // 'xnorfzt';

    # find matching entities
    my @entities = Coma::Entity->select('WHERE name LIKE ?', "%$str%");

    # render as json
    $c->render(json => [map $_->name => @entities]);
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

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';

%# enter a connection form
%= form_for 'index' => begin
    %= text_field from_entity => '', id => 'from_entity'
    %= text_field type => '', id => 'type'
    %= text_field to_entity => '', id => 'to_entity'
% end

%# auto-completion code
%= javascript begin
$(function() {
    $('#from_entity, #to_entity').autocomplete({
        source: '<%= url_for 'entity_completion' %>',
    });
    $('#type').autocomplete({
        source: '<%= url_for 'connection_completion' %>',
    });
});
% end

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
<head>
    <title><%= title %></title>
    %= javascript 'jquery.js'
    %= javascript 'jquery-ui.js'
    %= stylesheet 'jquery-ui.css'
</head>
<body>
%= content
</body>
</html>
