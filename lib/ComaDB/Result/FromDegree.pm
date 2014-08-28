use utf8;
package ComaDB::Result::FromDegree;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ComaDB::Result::FromDegree

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<from_degree>

=cut

__PACKAGE__->table("from_degree");

=head1 ACCESSORS

=head2 name

  data_type: 'string'
  is_nullable: 1

=head2 from_degree

  data_type: (empty string)
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "name",
  { data_type => "string", is_nullable => 1 },
  "from_degree",
  { data_type => "", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-08-28 02:01:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:64gl5lZ8C352iN/Ee7bJtw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
