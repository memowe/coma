use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME        => 'coma',
    VERSION     => '0.01',
    PREREQ_PM   => {
        'Mojolicious'       =>  '5.32',
        'ORLite'            =>  '1.98',
        'Text::Markdown'    =>  '1.0',
    },
    test        => {TESTS => 't/*.t'}
);
