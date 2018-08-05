package Coma::Command::export_tgf;
use Mojo::Base 'Mojolicious::Command', -signatures;

use Mojo::Util 'getopt';
use Mojo::File 'path';
use File::Temp 'tempdir';
use DateTime;

has description => "Dump single or more maps using TGF";
has usage       => <<USAGE;
Usage: coma export_tgf [OPTIONS]

    ./coma export_tgf
    ./coma export_tgf -d export/direc/tory
    ./coma export_tgf -i 4217

Options:
    -i, --id    Dumps only the map with the given ID.
                By default, all maps are dumped.
    -d, --dir   Dumps the list of events.
USAGE

sub run ($self, @args) {

    # Extract options
    getopt \@args,
        'i|id=i'    => \my $id,
        'd|dir=s'   => \my $dir;

    # Determine export directory
    # Given as command option and has to be created
    if (defined $dir and not -e $dir) {
        path($dir)->make_path;
        die "Directory '$dir' couldn't be created."
            unless -d $dir;
    }

    # Use default export directory
    elsif (not defined $dir) {
        my $pdir = $self->app->home->rel_file('export');
        make_path $pdir unless -d $pdir;
        $dir = tempdir
            DIR         => $pdir,
            TEMPLATE    => DateTime->now->iso8601 . '_XXXXXX';
    }

    # Tell
    die "Export directory '$dir' can't be used.\n"
        unless -e -d -w $dir;
    say "Export directory is '$dir'.";

    # What to export?
    my @maps;

    # Single ID given
    if (defined $id) {
        eval {@maps = $self->app->data->get_map_data($id)};
        say $1 if $@ =~ /(Unknown map: \d+)\R?/;
    }

    # Nothing given: export all
    else {
        push @maps, $self->app->data->get_map_data($_)
            for @{$self->app->data->get_all_map_ids};
    }

    # Nothing to export?
    unless (@maps) {
        say 'Nothing to export. Deleting export directory.';
        path($dir)->remove_tree;
        return;
    }

    # Export
    for my $map (@maps) {

        # Create a good file name
        (my $fn_name = $map->{name}) =~ s/\W+/_/g;
        my $filename = path($dir, $fn_name . '_' . $map->{id} . '.tgf');

        # Export
        open my $fh, '>', $filename
            or die "Couldn't open file '$filename': $!\n";
        print $fh $self->app->data->get_map_tgf($map->{id});
        close $fh;

        # Tell
        say 'Map ' . $map->{name} . ' (ID ' . $map->{id} . ") -> $filename";
    }

    # Tell
    say 'Done.';
}

1;
__END__
