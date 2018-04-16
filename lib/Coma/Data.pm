package Coma::Data;
use Mojo::Base -base;

use Coma::EventStore;

use List::Util 'max';

has events => sub { Coma::EventStore->new };

sub _get {
    my ($self, $key) = @_;
    return $self->events->state->{$key};
}

sub _generate_map_id {
    my $self = shift;

    # Look for the highest given map ID
    # or set it to -1, if nothing found
    my @keys = keys %{$self->_get('maps')};
    my $max  = max(@keys) // -1;

    # Next ID
    return $max + 1;
}

sub _generate_connection_id {
    my ($self, $map_id) = @_;

    # Look for the highest given connection ID
    # or set it to -1, if nothing found
    my @keys = keys %{$self->_get('maps')->{$map_id}{connections}};
    my $max  = max(@keys) // -1;

    # Next ID
    return $max + 1;
}

sub add_map {
    my ($self, $data) = @_;

    # Prepare
    my $id = $self->_generate_map_id;

    # Done
    $self->events->store_event(MapAdded => {
        id          => $id,
        name        => $data->{name},
        description => $data->{description},
    });
}

sub update_map_data {
    my ($self, $id, $data) = @_;

    # Exists? Retrieve old data
    my $map = $self->_get('maps')->{$id};
    die "Unknown map: $id\n" unless defined $map;

    # Update only what's given
    $map->{$_} = $data->{$_} for keys %$data;

    # Done
    $self->events->store_event(MapDataUpdated => $map);
}

sub remove_map {
    my ($self, $id) = @_;

    # Exists?
    die "Unknown map: $id\n"
        unless exists $self->_get('maps')->{$id};

    # Done
    $self->events->store_event(MapRemoved => {id => $id});
}

sub add_connection {
    my ($self, $map_id, $data) = @_;

    # Map exists?
    die "Unknown map: $map_id\n"
        unless exists $self->_get('maps')->{$map_id};

    # Prepare
    my $id = $self->_generate_connection_id($map_id);

    # Done
    $self->events->store_event(ConnectionAdded => {
        id      => $id,
        map     => $map_id,
        type    => $data->{type},
        from    => $data->{from},
        to      => $data->{to},
    });
}

sub update_connection {
    my ($self, $map_id, $id, $data) = @_;

    # Exists?
    my $map = $self->_get('maps')->{$map_id};
    die "Unknown map: $map_id\n" unless defined $map;
    my $connection = $map->{connections}{$id};
    die "Unknown connection: $map_id/$id\n" unless defined $connection;

    # Update only what's given
    $connection->{$_} = $data->{$_} for keys %$data;

    # Done
    $self->events->store_event(ConnectionUpdated => $connection);
}

sub remove_connection {
    my ($self, $map_id, $id) = @_;

    # Exists?
    my $map = $self->_get('maps')->{$map_id};
    die "Unknown map: $map_id\n" unless defined $map;
    die "Unknown connection: $map_id/$id\n"
        unless defined $map->{connections}{$id};

    # Done
    $self->events->store_event(ConnectionRemoved => {
        map => $map_id,
        id  => $id,
    });
}

1;
__END__
