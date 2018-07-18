use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'coma',
    VERSION             => '0.1',
    MIN_PERL_VERSION    => '5.20.0',
    PREREQ_PM           => {
        'Data::Dump'                    =>  '1.23',
        'DBIx::Class'                   =>  '0.08',
        'EventStore::Tiny'              =>  '0.4',
        'Mojolicious'                   =>  '7.88',
        'Text::Markdown'                =>  '1.0',
        'Graph::Centrality::Pagerank'   =>  '1.05',
    },
    test => {TESTS => 't/*.t'}
);
