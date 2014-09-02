use utf8;
package ComaDB::Result::MapEntity;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ComaDB::Result::MapEntity

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<map_entity>

=cut

__PACKAGE__->table("map_entity");

=head1 ACCESSORS

=head2 map_id

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'string'
  is_nullable: 1

=head2 degree

  data_type: (empty string)
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "map_id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "string", is_nullable => 1 },
  "degree",
  { data_type => "", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-08-28 02:01:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RgCmC7YNZww63Bq20Tye6Q

__PACKAGE__->belongs_to('entity',
    'ComaDB::Result::Entity',
    {'foreign.name' => 'self.name'},
);

__PACKAGE__->has_many('from_connections',
    'ComaDB::Result::Connection',
    {'foreign.from_name' => 'self.name', 'foreign.map_id' => 'self.map_id'},
);

__PACKAGE__->has_many('to_connections',
    'ComaDB::Result::Connection',
    {'foreign.from_name' => 'self.name', 'foreign.map_id' => 'self.map_id'},
);

__PACKAGE__->has_many('from_degrees',
    'ComaDB::Result::MapFromDegree',
    {'foreign.name' => 'self.name', 'foreign.map_id' => 'self.map_id'},
);

__PACKAGE__->has_many('to_degrees',
    'ComaDB::Result::MapToDegree',
    {'foreign.name' => 'self.name', 'foreign.map_id' => 'self.map_id'},
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
