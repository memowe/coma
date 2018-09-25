# coma: Getting Started Guide

Coma is a web app which is configured and started from terminal. This guide will hopefully lead you through all steps you need to run coma for the first time.

## Perl 5

A modern Perl 5 interpreter (at least v5.20, released May 2014) is required, which is not always pre-installed on operating systems. If you're unsure, the following shell command will tell you which `perl` version is available on your system:

    $ perl -v
    This is perl 5, version 26, subversion 1 (v5.26.1) built for x86_64-linux
    [...]

### Installation on Mac or Linux

The recommended way to manage recent or older Perl installations is using [perlbrew][]:

    $ \curl -L https://install.perlbrew.pl | bash
    $ perlbrew init
    $ perlbrew install perl-5.28.0
    $ perlbrew switch perl-5.28.0

Alternatively you can use your package manager (for Mac OS it might be [brew][]) or build perl from [source][].

### Installation on Windows

On **Windows** there are two [binary distributions][win] and an experimental perlbrew port named [berrybrew][].

### Managing perl modules

The recommended way to install perl modules is using [cpanm][] (CPAN minus). [Read more...][modules]

[brew]: https://dev.perl.org/perl5/source.html
[source]: https://dev.perl.org/perl5/source.html
[perlbrew]: https://perlbrew.pl/
[win]: https://www.perl.org/get.html#win32
[berrybrew]: http://blogs.perl.org/users/steve_bertrand/2016/07/berrybrew-the-perlbrew-for-windows-rewritten-and-enhanced.html
[cpanm]: https://metacpan.org/pod/App::cpanminus#Installing-to-system-perl
[modules]: http://www.cpan.org/modules/INSTALL.html

## Getting coma

As the coma code is managed completely in a git repository, you just [clone][] the repository:

    $ git clone URL
    Cloning into 'coma'...
    [...]

If you're working with coma for the AGV, where coma was developed, and you're looking for a lot of TGF data from CS1, check the *data_collections* repository.

[clone]: https://git-scm.com/docs/git-clone

## Module dependencies

To get an idea which modules coma needs, have a look at the file [`Makefile.PL`][makefile]. If cpanm is installed (see above), getting all dependencies is easy:

    $ cd coma
    $ cpanm -n --installdeps .

[makefile]: ../Makefile.PL

## First steps

You don't install coma. You just run it from the directory you put its code in. To check if everything is set up correctly, run the test suite:

    coma$ prove -lr
    [...]
    All tests successful.
    [...]

As coma is a standard [Mojolicious][mojo] web app, it can be run by firing its development server [morbo][]:

    $ morbo coma
    Server available at http://127.0.0.1:3000

Just open that address in your web browser and have a look at the example data or add new maps. To work efficiently with external data, have a look at the [commands][].

[mojo]: https://mojolicious.org/
[morbo]: https://mojolicious.org/perldoc/morbo
[commands]: Commands.md
