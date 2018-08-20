package Coma::Data::EventStore;
use Mojo::Base -base, -signatures;

use EventStore::Tiny;

has data_filename => ();
has _est => sub ($self) {
    my $est_fn = $self->data_filename;

    # Create event store
    my $store = (defined $est_fn and -e $est_fn)
        ? EventStore::Tiny->new_from_file($est_fn)
        : EventStore::Tiny->new;
    $store->cache_distance(0);
    $store->slack(1);

    return $store;
};

sub store_to_file ($self) {
    die "No data_filename given!\n"
        unless defined $self->data_filename;
    $self->_est->store_to_file($self->data_filename);
}

# Helper
sub store_event ($self, @args) {$self->_est->store_event(@args)}
sub logger ($self, @args) {$self->_est->logger(@args)}

sub init ($self) {

    # Will be used for two events
    my $set_map = sub ($state, $data) {
        $state->{maps}{$data->{id}} = {
            id          => $data->{id},
            name        => $data->{name},
            description => $data->{description},
        };
    };

    # A concept map has been added
    $self->_est->register_event(MapAdded => $set_map);

    # A concept map's data has been updated
    $self->_est->register_event(MapDataUpdated => $set_map);

    # A concept map has been removed
    $self->_est->register_event(MapRemoved => sub ($state, $data) {
        delete $state->{maps}{$data->{id}};
    });

    # Will be used for two events
    my $set_connection = sub ($state, $data) {
        $state->{maps}{$data->{map}}{connections}{$data->{id}} = {
            id      => $data->{id},
            map     => $data->{map},
            type    => $data->{type},
            from    => $data->{from},
            to      => $data->{to},
        };
    };

    # A connection between two entities has been added to a map
    $self->_est->register_event(ConnectionAdded => $set_connection);

    # A connection has been updated
    $self->_est->register_event(ConnectionUpdated => $set_connection);

    # A connection has been removed from a map
    $self->_est->register_event(ConnectionRemoved => sub ($state, $data) {
        delete $state->{maps}{$data->{map}}{connections}{$data->{id}};
    });
}

sub is_empty ($self) {
    return $self->_est->events->size == 0;
}

sub last_update ($self) {
    return $self->_est->events->last_timestamp // 0;
}

sub state ($self, $time = undef) {
    return $self->_est->snapshot($time)->state;
}

1;
__END__
