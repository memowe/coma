package Coma::Data;
use Mojo::Base -base;

use Coma::Data::EventStore;

use List::Util 'max';

has data_filename => ();
has events => sub {
    my $events = Coma::Data::EventStore->new(
        data_filename => shift->data_filename,
    );
    $events->init;
    return $events;
};

sub store {
    my $self = shift;
    $self->events->store_to_file;
}

sub _get {
    my ($self, $key) = @_;
    return $self->events->state->{$key};
}

sub _generate_map_id {
    my $self = shift;

    # Look for the highest given map ID
    # or set it to -1, if nothing found
    my @keys = keys %{$self->_get('maps') // {}};
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

    # Store event
    $self->events->store_event(MapAdded => {
        id          => $id,
        name        => $data->{name},
        description => $data->{description},
    });

    # Done
    return $id;
}

sub get_map_data {
    my ($self, $id) = @_;

    # Exists?
    my $map = $self->_get('maps')->{$id};
    die "Unknown map: $id\n" unless defined $map;

    # found
    return $map;
}

sub get_all_map_ids {
    my $self = shift;

    my @ids = keys %{$self->_get('maps') // {}};
    return [sort {$a <=> $b} @ids];
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

    # Store event
    $self->events->store_event(ConnectionAdded => {
        id      => $id,
        map     => $map_id,
        type    => $data->{type},
        from    => $data->{from},
        to      => $data->{to},
    });

    # Done
    return $id;
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

# Per map or across all maps
# Returns a hash with entites as keys and degree as values
sub get_entity_degrees {
    my ($self, $map_id) = @_; # map_id: optional
    return $self->_get_entity_degrees('both', $map_id);
}
sub get_entity_indegrees {
    my ($self, $map_id) = @_; # map_id: optional
    return $self->_get_entity_degrees('to', $map_id);
}
sub get_entity_outdegrees {
    my ($self, $map_id) = @_; # map_id: optional
    return $self->_get_entity_degrees('from', $map_id);
}

sub _get_entity_degrees {
    my ($self, $type, $map_id) = @_; # map_id: optional

    # Count connections for each matching map
    my %degree;
    for my $map (@{$self->_get_maps($map_id)}) {

        # Look at each connection
        for my $con (values %{$map->{connections}}) {
            $degree{$con->{from}}++ if $type eq 'from' or $type eq 'both';
            $degree{$con->{to}}++   if $type eq 'to'   or $type eq 'both';
        }
    }

    # Done
    return \%degree;
}

sub _get_maps {
    my ($self, $map_id) = @_; # map_id: optional
    my @maps;

    # Single map
    if (defined $map_id) {
        my $map = $self->_get('maps')->{$map_id};
        die "Unknown map: $map_id\n" unless defined $map;
        push @maps, $map;
    }

    # All maps
    else {
        @maps = map {$self->_get('maps')->{$_}} @{$self->get_all_map_ids};
    }

    # Done
    return \@maps;
}

sub get_entities {
    my ($self, $map_id) = @_; # map_id: optional
    return [sort keys %{$self->get_entity_degrees($map_id)}];
}

sub get_connection_types {
    my ($self, $map_id) = @_; # map_id: optional

    # Collect connection types (with duplicates
    my @types;
    for my $map (@{$self->_get_maps($map_id)}) {
        my @map_connections = values %{$map->{connections}};
        push @types, map {$_->{type}} @map_connections;
    }

    # Sum occurrences
    my %type_count;
    $type_count{$_}++ for @types;

    # Done
    return \%type_count;
}

1;
__END__
