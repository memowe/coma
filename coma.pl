#!/usr/bin/env perl

use Mojolicious::Lite;

# read config file
BEGIN { # need this namespace magic to insert example entities early
    our $config = plugin 'Config';
};
my $config = $main::config;

# prepare database access
use ORLite {
    package     => 'Coma',
    file        => app->home->rel_file('data/graph.sqlite'),
    unicode     => 1,
    create      => sub {
        my $dbh     = shift;
        my $config  = $main::config;

        # create database scheme
        $dbh->do('
        CREATE TABLE entity (
            id      INTEGER PRIMARY KEY,
            name    STRING
        );');

        # insert some example entities
        my $insert = $dbh->prepare('INSERT INTO entity (name) VALUES (?)');
        $insert->execute($_) for @{$config->{example_entities}};
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

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';

%# auto-completion form
%= form_for 'index' => begin
    %= text_field entity => '', id => 'entity'
% end

%# auto-completion code
%= javascript begin
$(function() {
    $('#entity').autocomplete({
        source: '<%= url_for 'entity_completion' %>',
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
