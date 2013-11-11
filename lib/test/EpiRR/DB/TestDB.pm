package EpiRR::DB::TestDB;

use strict;
use warnings;
use autodie;

use DBI;
use Moose;
use EpiRR::Model;

has 'schema' => ( is => 'rw', isa => 'EpiRR::Model' );
has 'url' =>
  ( is => 'rw', isa => 'Str', default => 'dbi:SQLite:dbname=:memory:' );
has 'dbh'          => ( is => 'rw' );
has 'status_name'  => ( is => 'ro', isa => 'Str', default => 'Test Status' );
has 'archive_name' => ( is => 'ro', isa => 'Str', default => 'TA' );
has 'archive_full_name' =>
  ( is => 'ro', isa => 'Str', default => 'test archive' );
has 'project_name'   => ( is => 'ro', isa => 'Str', default => 'Test Project' );
has 'project_prefix' => ( is => 'ro', isa => 'Str', default => 'TPX' );

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
    $self->schema()->status()->create( { status => $self->status_name() } );
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

    my $schema_file = '/Users/davidr/EpiRR/sql/schema.sqlite.sql';
    my $content     = '';
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
    my $schema = EpiRR::Model->connect( sub { $self->dbh() } );
    $self->schema($schema);
}

sub tear_down {
    #
}

1;
