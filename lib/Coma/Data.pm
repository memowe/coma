package Coma::Data;
use Mojo::Base -base, -signatures;

use Coma::Data::EventStore;

use File::stat;
use List::Util 'max';

has data_filename   => ();
has last_storage    => sub ($self) {

    # Is there already something? Use it's last modified time
    my $dfn = $self->data_filename;
    return stat($dfn)->mtime if defined $dfn and -e $dfn;

    # Nothing to read from
    return 0;
};
has events => sub ($self) {
    my $events = Coma::Data::EventStore->new(
        data_filename => $self->data_filename,
    );
    $events->init;
    return $events;
};

sub logger ($self, $logger = undef) {
    $self->events->logger($logger);
}

sub store ($self) {
    $self->events->store_to_file;
    $self->last_storage($self->events->last_update);
}

# Returns true iff it was neccessary
sub store_if_neccessary ($self) {

    # Updated since last storage: neccessary
    if ($self->last_update > $self->last_storage) {
        $self->store;
        return 1;
    }

    # Not neccessary
    return;
}

sub is_empty ($self) {
    return $self->events->is_empty;
}

sub last_update ($self) {
    return $self->events->last_update;
}

sub _get ($self, $key) {
    return $self->events->state->{$key};
}

sub _generate_map_id ($self) {

    # Look for the highest given map ID
    # or set it to -1, if nothing found
    my @keys = keys %{$self->_get('maps') // {}};
    my $max  = max(@keys) // -1;

    # Next ID
    return $max + 1;
}

sub _generate_connection_id ($self, $map_id) {

    # Look for the highest given connection ID
    # or set it to -1, if nothing found
    my @keys = keys %{$self->_get('maps')->{$map_id}{connections}};
    my $max  = max(@keys) // -1;

    # Next ID
    return $max + 1;
}

sub add_map ($self, $data) {

    # Prepare
    my $id = $self->_generate_map_id;

    # Store event
    $self->events->store_event(MapAdded => {
        id          => $id,
        name        => $data->{name},
        description => $data->{description},
    });

    return $id;
}

sub get_map_data ($self, $id) {

    # Exists?
    my $map = $self->_get('maps')->{$id};
    die "Unknown map: $id\n" unless defined $map;

    # found
    return $map;
}

sub get_all_map_ids ($self) {

    my @ids = keys %{$self->_get('maps') // {}};
    return [sort {$a <=> $b} @ids];
}

sub update_map_data ($self, $id, $data) {

    # Exists? Retrieve old data
    my $map = $self->_get('maps')->{$id};
    die "Unknown map: $id\n" unless defined $map;

    # Use/update only relevant data
    my $update = {map {
        $_ => $data->{$_} // $map->{$_}
    } qw(id name description)};

    $self->events->store_event(MapDataUpdated => $update);
}

sub remove_map ($self, $id) {

    # Exists?
    die "Unknown map: $id\n"
        unless exists $self->_get('maps')->{$id};

    $self->events->store_event(MapRemoved => {id => $id});
}

sub add_connection ($self, $map_id, $data) {

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

    return $id;
}

sub update_connection ($self, $map_id, $id, $data) {

    # Exists?
    my $map = $self->_get('maps')->{$map_id};
    die "Unknown map: $map_id\n" unless defined $map;
    my $connection = $map->{connections}{$id};
    die "Unknown connection: $map_id/$id\n" unless defined $connection;

    # Use/update only relevant data
    my $update = {map {
        $_ => $data->{$_} // $connection->{$_}
    } qw(id map type from to)};

    $self->events->store_event(ConnectionUpdated => $update);
}

sub remove_connection ($self, $map_id, $id) {

    # Exists?
    my $map = $self->_get('maps')->{$map_id};
    die "Unknown map: $map_id\n" unless defined $map;
    die "Unknown connection: $map_id/$id\n"
        unless defined $map->{connections}{$id};

    $self->events->store_event(ConnectionRemoved => {
        map => $map_id,
        id  => $id,
    });
}

sub _get_maps ($self, $map_id = undef) {
    my @maps;

    # Single map
    if (defined $map_id) {
        my $map = $self->get_map_data($map_id);
        die "Unknown map: $map_id\n" unless defined $map;
        push @maps, $map;
    }

    # All maps
    else {
        @maps = map {$self->get_map_data($_)} @{$self->get_all_map_ids};
    }

    return \@maps;
}

sub has_entity ($self, $entity, $map_id = undef) {
    return exists $self->get_entity_degrees($map_id)->{$entity};
}

sub get_map_ids_with_entity ($self, $entity) {
    return [grep {$self->has_entity($entity, $_)} @{$self->get_all_map_ids}];
}

sub get_entities ($self, $map_id = undef) {
    return [sort keys %{$self->get_entity_degrees($map_id)}];
}

sub get_connections ($self, $map_id = undef) {

    # Extract connections from all matching maps
    my @cs = map {values %{$_->{connections}}} @{$self->_get_maps($map_id)};

    # Get rid of IDs as they don't make sense here
    delete $_->{id}  for @cs;
    delete $_->{map} for @cs;

    # Sort by from, to and type
    @cs = sort {
            $a->{from} cmp $b->{from}
        ||  $a->{to}   cmp $b->{to}
        ||  $a->{type} cmp $b->{type}
    } @cs;

    return \@cs;
};

sub get_connection_types ($self, $map_id = undef) {

    # extract types with duplicates
    my @types = map {$_->{type}} @{$self->get_connections($map_id)};

    # Sum occurrences
    my %type_count;
    $type_count{$_}++ for @types;

    return \%type_count;
}

sub get_connection_pairs ($self, $map_id = undef) {
    return [map {[$_->{from} => $_->{to}]} @{$self->get_connections($map_id)}];
}

# Per map or across all maps
# Returns a hash with entites as keys and degree as values
sub get_entity_degrees ($self, $map_id = undef) {
    return $self->_get_entity_degrees('both', $map_id);
}
sub get_entity_indegrees ($self, $map_id = undef) {
    return $self->_get_entity_degrees('to', $map_id);
}
sub get_entity_outdegrees ($self, $map_id = undef) {
    return $self->_get_entity_degrees('from', $map_id);
}

sub _get_entity_degrees ($self, $type, $map_id = undef) {

    # Count connections for each matching map
    my %degree;
    for my $map (@{$self->_get_maps($map_id)}) {

        # Look at each connection
        for my $con (values %{$map->{connections}}) {
            $degree{$con->{from}}++ if $type eq 'from' or $type eq 'both';
            $degree{$con->{to}}++   if $type eq 'to'   or $type eq 'both';
        }
    }

    return \%degree;
}

sub get_neighbourhood ($self, $entity, $map_id = undef) {
    return $self->_get_neighbourhood('both', $entity, $map_id);
}
sub get_incoming_neighbourhood ($self, $entity, $map_id = undef) {
    return $self->_get_neighbourhood('in', $entity, $map_id);
}
sub get_outgoing_neighbourhood ($self, $entity, $map_id = undef) {
    return $self->_get_neighbourhood('out', $entity, $map_id);
}

sub _get_neighbourhood ($self, $type, $entity, $map_id = undef) {

    # Select relevant from all connections
    my %entities;
    for my $c (@{$self->get_connections($map_id)}) {

        # Incoming
        $entities{$c->{from}}++
            if ($type eq 'in' or $type eq 'both')
                and $c->{to} eq $entity;

        # Outgoing
        $entities{$c->{to}}++
            if ($type eq 'out' or $type eq 'both')
                and $c->{from} eq $entity;
    }

    return [sort keys %entities];
}

sub get_map_tgf ($self, $map_id) {

    # Retrieve map
    my $map = $self->get_map_data($map_id);
    die "Unknown map: $map_id\n" unless defined $map;

    # Prepare
    my $tgf = '';

    # Collect all entities
    my %entity_id   = ();
    my $last_id     = 0;
    $entity_id{$_}  = ++$last_id for @{$self->get_entities($map_id)};

    # Write entities
    $tgf .= "$entity_id{$_} $_\n" for sort keys %entity_id;
    $tgf .= "#\n";

    # Write connections
    my $cs = $self->get_connections($map_id);
    $tgf .= "$entity_id{$_->{from}} $entity_id{$_->{to}} $_->{type}\n" for @$cs;

    return $tgf;
}

sub add_map_from_tgf ($self, $name, $description, $tgf) {

    # Prepare TGF lines
    my @tgf_lines = split /\R+/ => $tgf;

    # Parse entities
    my %es;
    while (defined(my $line = shift @tgf_lines)) {
        last if $line =~ /^#$/;
        next unless $line =~ /^(\d+)\s+(.*)/;
        $es{$1} = $2;
    }

    # Parse connections
    my @cs;
    while (defined(my $line = shift @tgf_lines)) {
        next unless $line =~ /^(\d+)\s+(\d+)\s+(.*)$/;

        # Look up entities
        my $from = $es{$1} // die "Unknown from: $1\n";
        my $to   = $es{$2} // die "Unknown to: $2\n";

        # Store connection data
        push @cs, {from => $from, to => $to, type => $3};
    }

    # Prepare map
    my $map_id = $self->add_map({
        name        => $name,
        description => $description,
    });

    # Add connections
    $self->add_connection($map_id, $_) for @cs;

    return $map_id;
}

sub add_map_from_tgf_file ($self, $name, $description, $filename) {

    # Read from file
    open my $fh, '<', $filename or die "Couldn't open $filename: $!\n";
    my $tgf = do {local $/; <$fh>};
    close $fh;

    # Parse and return generated ID
    return $self->add_map_from_tgf($name, $description, $tgf);
}

1;
__END__
