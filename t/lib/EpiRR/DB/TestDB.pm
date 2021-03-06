# Copyright 2013 European Molecular Biology Laboratory - European Bioinformatics Institute
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
package EpiRR::DB::TestDB;

use autodie;

use DBI;
use Moose;
use EpiRR::Schema;
use Cwd qw/abs_path/;
use File::Basename;
use namespace::autoclean;

has 'schema' => ( is => 'rw', isa => 'EpiRR::Schema' );
has 'url' =>
  ( is => 'rw', isa => 'Str', default => 'dbi:SQLite:dbname=:memory:' );

has 'dbh' => ( is => 'rw' );
has 'archive_name' => ( is => 'ro', isa => 'Str', default => 'TA' );
has 'archive_full_name' =>
  ( is => 'ro', isa => 'Str', default => 'test archive' );
has 'project_name'   => ( is => 'ro', isa => 'Str', default => 'Test Project' );
has 'project_prefix' => ( is => 'ro', isa => 'Str', default => 'TPX' );
has 'status_name'    => ( is => 'ro', isa => 'Str', default => 'Complete' );
has 'type_name'      => ( is => 'ro', isa => 'Str', default => 'Single donor' );

sub build_up {
    my ($self) = @_;

    $self->_create_dbh();
    $self->_create_db();
    $self->_create_schema();

    return $self->schema();
}

sub populate_basics {
    my ($self) = @_;
    $self->schema()->archive()->create(
        {
            name      => $self->archive_name(),
            full_name => $self->archive_full_name()
        }
    );
    for (qw(DEFAULT Complete Partial)) {
        $self->schema()->status()->create( { name => $_ } );
    }
    for ( 'DEFAULT', 'Single donor', 'Pooled samples', 'Composite' ) {

        $self->schema()->type()->create( { name => $_ } );
    }

    $self->schema()->project()
      ->create(
        { name => $self->project_name(), id_prefix => $self->project_prefix() }
      );

}

sub _create_dbh {
    my ($self) = @_;
    my $dbh = DBI->connect( $self->url(), "", "", { 'RaiseError' => 1 } );
    $dbh->do("PRAGMA foreign_keys = ON");
    $self->dbh($dbh);
}

sub _create_db {
    my ($self) = @_;

    my $module_dir = dirname(__FILE__);
    my $schema_file =
      abs_path( $module_dir . '/../../../../sql/schema.sqlite.sql' );

    my $content = '';
    open my $fh, '<', $schema_file;
    {
        local $/;
        $content = <$fh>;
    }
    close $fh;

    for my $statement ( split /;/, $content ) {
        $self->dbh()->do($statement);
        if ( $self->dbh()->err() ) {
            croak $self->dbh()->errstr();
        }
    }
}

sub _create_schema {
    my ($self) = @_;
    my $schema = EpiRR::Schema->connect( sub { $self->dbh() } );
    $self->schema($schema);
}
__PACKAGE__->meta->make_immutable;

1;
