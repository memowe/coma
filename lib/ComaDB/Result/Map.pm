use utf8;
package ComaDB::Result::Map;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ComaDB::Result::Map

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<map>

=cut

__PACKAGE__->table("map");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'string'
  is_nullable: 1

=head2 description

  data_type: 'string'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "string", is_nullable => 1 },
  "description",
  { data_type => "string", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 connections

Type: has_many

Related object: L<ComaDB::Result::Connection>

=cut

__PACKAGE__->has_many(
  "connections",
  "ComaDB::Result::Connection",
  { "foreign.map_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-08-28 02:01:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Rpjt7Y7K7RmFJoHfSSN/2g

__PACKAGE__->has_many(map_entities => 'ComaDB::Result::MapEntity',
    {'foreign.map_id' => 'self.id'},
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub to_tgf {
    my $self = shift;

    # prepare
    my $output = "";

    # collect all entities
    my %entity_id   = ();
    my $last_id     = 0;
    $entity_id{$_}  = ++$last_id
        for sort $self->map_entities->get_column('name')->all;

    # write entities
    $output .= "$entity_id{$_} $_\n"
        for sort keys %entity_id;

    # write entity connection separator
    $output .= "#\n";

    # write connections
    for my $c ($self->connections->all) {
        my ($from, $to, $name) = map {$c->$_} qw(from_name to_name type);
        $output .= "$entity_id{$from} $entity_id{$to} $name\n";
    }

    # done
    return $output;
}

1;
