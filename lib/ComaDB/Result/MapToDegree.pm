use utf8;
package ComaDB::Result::MapToDegree;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ComaDB::Result::MapToDegree

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<map_to_degree>

=cut

__PACKAGE__->table("map_to_degree");

=head1 ACCESSORS

=head2 map_id

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'string'
  is_nullable: 1

=head2 to_degree

  data_type: (empty string)
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "map_id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "string", is_nullable => 1 },
  "to_degree",
  { data_type => "", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-08-28 02:01:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TSO45PRZY5qcOwYCW0+bIg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
