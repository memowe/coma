#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use FindBin '$Bin';

# prepare test database
$ENV{COMA_DB} = "$Bin/graph.sqlite";
ok ! -e $ENV{COMA_DB}, 'no test database found';

# get the lite script
require "$Bin/../coma.pl";

# got a test database?
ok -e $ENV{COMA_DB}, 'test database found';

# prepare
my $t = Test::Mojo->new;
$t->ua->max_redirects(1);

# connection not there yet
$t->get_ok('/')->content_unlike(qr/Perl isa Programmiersprache/);

# add the new connection
$t->post_ok('/add_connection', form => {
    from_entity => 'Perl', type => 'isa', to_entity => 'Programmiersprache'
});

# now it's there
$t->content_like(qr/Perl isa Programmiersprache/);

# cleanup
unlink $ENV{COMA_DB};
ok ! -e $ENV{COMA_DB}, 'test database removed';

done_testing;
