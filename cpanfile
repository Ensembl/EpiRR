requires 'DBIx::Class';
requires 'Moose';
requires 'Class::Method::Modifiers';
requires 'XML::Twig';
requires 'URI::Encode';

on 'test' => sub {
  requires 'Test::More';
  requires 'DBD::SQLite';
};

on 'build' => sub {
  requires 'Module::Build::Pluggable';
  requires 'Module::Build::Pluggable::CPANfile';
};
