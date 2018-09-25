package Coma::Command::import_tgf;
use Mojo::Base 'Mojolicious::Command', -signatures;

use feature 'say';

use Mojo::Util 'getopt';
use Mojo::File 'path';

has description => 'Import maps as graphs from TGF files';
has usage       => <<USAGE;
Usage: coma import_tgf [OPTIONS] FILENAME

    ./coma import_tgf map.tgf
    ./coma import_tgf -n foo -d 'bar baz' map.tgf

Options:
    -n, --name          Set a name for the imported map.
    -d, --descriotion   Set a description for the imported map,
                        interpreted by markdown.
USAGE

sub run ($self, @args) {

    # Extract name and description from command line options
    getopt \@args,
        'n|name=s'          => \(my $name           = ''),
        'd|description=s'   => \(my $description    = '');

    # Extract filename
    my $filename = shift @args // '';
    die "Unknown file '$filename'!" unless -r $filename;

    # Extract name from filename, if not set
    $name = path($filename)->basename('.tgf')
        if $name eq '';

    # Open that file
    open my $fh, '<:encoding(UTF-8)', $filename
        or die "Couldn't open $filename: $!";

    # Iterate lines
    say "Processing $filename...";
    my %concept = ();
    my @links   = ();
    while (<$fh>) {
        chomp;

        # File section markers (this is magic)
        my $concept_section = 1 .. /^#$/;
        my $link_section    = /^#$/ .. eof;

        # First section: concepts like "12345 foo"
        if ($concept_section and /^(\d+) (.*)/) {
            $concept{$1} = $2;
        }

        # Second section: links like "23456 34567 bar"
        if ($link_section and /^(\d+) (\d+) (.*)/) {
            warn "Unknown concept $1\n" unless exists $concept{$1};
            warn "Unknown concept $2\n" unless exists $concept{$2};
            push @links, {
                from    => $concept{$1},
                type    => $3,
                to      => $concept{$2},
            };
        }
    }

    # Delete duplicate links
    my %unique_links = ();
    $unique_links{"$_->{from}-$_->{type}-$_->{to}"} = $_ for @links;
    my @unique_links = values %unique_links;

    # Log
    my $concept_c   = keys %concept;
    my $link_c      = @links;
    my $dupl_link_c = @links - @unique_links;
    say "    $concept_c concepts and $link_c links ($dupl_link_c duplicates)";

    # Store it in the model
    my $map_id = $self->app->data->add_map({
        name        => $name,
        description => $description,
    });
    $self->app->data->add_connection($map_id, $_)
        for @unique_links;

    $self->app->data->store_if_neccessary;
    say "    Generated map has ID $map_id.";
}

1;
__END__
