use utf8;
package ComaDB::Result::Connection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ComaDB::Result::Connection

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<connection>

=cut

__PACKAGE__->table("connection");

=head1 ACCESSORS

=head2 map_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 from_name

  data_type: 'string'
  is_nullable: 0

=head2 type

  data_type: 'string'
  is_nullable: 0

=head2 to_name

  data_type: 'string'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "map_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "from_name",
  { data_type => "string", is_nullable => 0 },
  "type",
  { data_type => "string", is_nullable => 0 },
  "to_name",
  { data_type => "string", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</map_id>

=item * L</from_name>

=item * L</type>

=item * L</to_name>

=back

=cut

__PACKAGE__->set_primary_key("map_id", "from_name", "type", "to_name");

=head1 RELATIONS

=head2 map

Type: belongs_to

Related object: L<ComaDB::Result::Map>

=cut

__PACKAGE__->belongs_to(
  "map",
  "ComaDB::Result::Map",
  { id => "map_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-08-28 02:01:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5kvEhCEYq4G6hwleaoT0xg

__PACKAGE__->belongs_to('from_entity',
    'ComaDB::Result::Entity',
    {'foreign.name' => 'self.from_name'},
);

__PACKAGE__->belongs_to('to_entity',
    'ComaDB::Result::Entity',
    {'foreign.name' => 'self.to_name'},
);

__PACKAGE__->belongs_to('map',
    'ComaDB::Result::Map',
    {'foreign.id' => 'self.map_id'},
);

use overload '""' => sub {
    my $self = shift;
    return $self->from_name . ' -' . $self->type . '-> ' . $self->to_name;
};

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
