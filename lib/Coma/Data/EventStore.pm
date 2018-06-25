package Coma::Data::EventStore;
use Mojo::Base -base;

use EventStore::Tiny;

has data_filename => ();
has _est => sub {
    my $self    = shift;
    my $est_fn  = $self->data_filename;

    # Create event store
    my $store = (defined $est_fn and -e $est_fn)
        ? EventStore::Tiny->new_from_file($est_fn)
        : EventStore::Tiny->new;
    $store->cache_size(0);

    # Done
    return $store;
};

sub store_to_file {
    my $self = shift;
    die "No data_filename given!\n"
        unless defined $self->data_filename;
    $self->_est->store_to_file($self->data_filename);
}

# Helper
sub store_event {shift->_est->store_event(@_)}
sub logger {shift->_est->logger(@_)}

sub init {
    my $self = shift;

    # Will be used for two events
    my $set_map = sub {
        my ($state, $data) = @_;
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
    $self->_est->register_event(MapRemoved => sub {
        my ($state, $data) = @_;
        delete $state->{maps}{$data->{id}};
    });

    # Will be used for two events
    my $set_connection = sub {
        my ($state, $data) = @_;
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
    $self->_est->register_event(ConnectionRemoved => sub {
        my ($state, $data) = @_;
        delete $state->{maps}{$data->{map}}{connections}{$data->{id}};
    });
}

sub state {
    my $self = shift;
    return $self->_est->snapshot->state;
}

1;
__END__
