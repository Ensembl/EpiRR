drop table if exists meta_data;
drop table if exists raw_data;
drop table if exists dataset_version;
drop table if exists dataset;
drop table if exists archive;
drop table if exists status;
drop table if exists project;


create table archive (
name text primary key,
full_name text
);

create table status (
status text primary key
);

create table project (
project_id integer primary key,
name text,
id_prefix text
);

create table dataset (
dataset_id integer primary key,
project_id integer,
accession text,
constraint dpi foreign key (project_id) references project(project_id)
);

create index i_ds_pi on dataset(project_id);
create index i_ds_acession on dataset(accession);


create table dataset_version (
dataset_version_id integer primary key,
dataset_id integer,
version integer,
is_current boolean,
local_name text,
description text,
full_accession text,
status text,
constraint dvd foreign key (dataset_id) references dataset(dataset_id),
constraint dvs foreign key (status) references status(status)
);

create index i_dv_ds on dataset_version(dataset_id);
create index i_dv_s on dataset_version(status);

create table meta_data (
meta_data_id integer primary key,
dataset_version_id integer,
name text,
value text,
foreign key (dataset_version_id) references dataset_version(dataset_version_id)
);

create index i_md_dsv on meta_data(dataset_version_id);

create table raw_data (
raw_data_id integer primary key,
dataset_version_id integer,
primary_accession text, 
secondary_accession text,
archive text,
archive_url text,
foreign key (dataset_version_id) references dataset_version(dataset_version_id),
foreign key (archive) references archive(name)
);

create index i_rd_ds on raw_data(dataset_version_id);
create index i_rd_a on raw_data(archive);
