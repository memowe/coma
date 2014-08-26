use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME        => 'coma',
    VERSION     => '0.01',
    PREREQ_PM   => {
        'DBIx::Class'                   =>  '0.08',
        'DBIx::Class::Schema::Loader'   =>  '0.07',
        'Mojolicious'                   =>  '5.32',
        'Text::Markdown'                =>  '1.0',
    },
    test        => {TESTS => 't/*.t'}
);
