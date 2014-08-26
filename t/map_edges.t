#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use FindBin '$Bin';

# prepare test database
$ENV{COMA_DB} = "$Bin/graph.sqlite";
ok -e $ENV{COMA_DB}, 'no test database found';

# get the lite script
require "$Bin/../coma.pl";

# prepare
my $t = Test::Mojo->new;
$t->ua->max_redirects(1);

# connection not there yet
my $text = $t->get_ok('/map/1')->tx->res->dom->all_text;
unlike $text => qr/Perl isa Programmiersprache/, 'no perl connection';

# add the new connection
$t->post_ok('/map/1', form => {
    from => 'Perl', type => 'isa', to => 'Programmiersprache'
});

# now it's there
$text = $t->tx->res->dom->all_text;
like $text => qr/Perl isa Programmiersprache/, 'perl connection found';

# delete it
$t->post_ok('/map/1/delete_connection', form => {
    from => 'Perl', type => 'isa', to => 'Programmiersprache'
});

# it's gone again
$text = $t->get_ok('/map/1')->tx->res->dom->all_text;
unlike $text => qr/Perl isa Programmiersprache/, 'perl connection gone';

done_testing;
