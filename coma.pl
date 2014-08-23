#!/usr/bin/env perl

use Mojolicious::Lite;
use Mojo::Util 'trim';

# prepare database access
use ORLite {
    package     => 'Coma',
    file        => $ENV{COMA_DB} // app->home->rel_file('data/graph.sqlite'),
    unicode     => 1,
    create      => sub {
        my $dbh = shift;

        # create the table for connections
        $dbh->do('CREATE TABLE connection (
            from_name   STRING,
            type        STRING,
            to_name     STRING,
            PRIMARY KEY (from_name, to_name, type)
        );');

        # insert some example connections
        my $insert = $dbh->prepare('INSERT INTO connection
            (from_name, type, to_name) VALUES (?, ?, ?)
        ');
        $insert->execute(@$_) for @{[
            [qw(Java isa Programmiersprache)],
            [qw(Java has JVM)],
            [qw(Programmiersprache isa JVM)],
        ]};
    },
};

# insert form and overview
get '/' => sub {
    my $c = shift;
    $c->stash(connections => [Coma::Connection->select]);
} => 'index';

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

# add a connection
post '/add_connection' => sub {
    my $c = shift;

    # build and insert a new connection
    my $connection  = Coma::Connection->new(
        from_name   => trim($c->param('from_entity')),
        type        => trim($c->param('type')),
        to_name     => trim($c->param('to_entity')),
    )->insert;

    # done
    $c->redirect_to('index');
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';

%# enter a connection form
%= t h2 => 'new edges'
%= form_for 'add_connection' => begin
    %= text_field from_entity => '', id => 'from_entity'
    %= text_field type => '', id => 'type'
    %= text_field to_entity => '', id => 'to_entity'
    %= submit_button 'add connection'
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

%# dump everything
%= t h2 => 'everything'
%= t ol => begin
% for my $conn (@$connections) {
    %= t li => join ' ' => map $conn->$_ => qw(from_name type to_name)
% }
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
