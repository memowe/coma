use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'coma',
    VERSION         => '0.1',
    PREREQ_PM       => {
        'DBIx::Class'                   =>  '0.08',
        'EventStore::Tiny'              =>  '0.3',
        'Mojolicious'                   =>  '5.68',
        'Text::Markdown'                =>  '1.0',
        'Graph::Centrality::Pagerank'   =>  '1.05',
        'experimental'                  =>  '0.013',
    },
    test            => {TESTS => 't/*.t'}
);
