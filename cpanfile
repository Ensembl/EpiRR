requires 'DBIx::Class';
requires 'Moose';
requires 'Class::Method::Modifiers';

on 'test' => sub {
	requires 'Test::More';
	requires 'DBD::SQLite';
}