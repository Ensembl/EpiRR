requires 'DBIx::Class';
requires 'Moose';
requires 'Class::Method::Modifiers';
requires 'XML::Twig';
requires 'URI::Encode';
requires 'Bread::Board';
requires 'LWP';
requires 'LWP::Protocol::https';
requires 'Mojolicious';
requires 'Bio::Perl';
requires 'Bio::DB::EUtilities';

on 'test' => sub {
  requires 'Test::More';
	requires 'Test::MockObject::Extends',
  requires 'DBD::SQLite';
};

on 'build' => sub {
  requires 'Module::Build::Pluggable';
  requires 'Module::Build::Pluggable::CPANfile';
};
