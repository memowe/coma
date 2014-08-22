use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    VERSION   => '0.01',
    PREREQ_PM => {
        'Mojolicious'   =>  '5.32',
        'ORLite'        =>  '1.98',
    },
    test      => {TESTS => 't/*.t'}
);
