drop table if exists meta_data;
drop table if exists raw_data;
drop table if exists dataset_version;
drop table if exists dataset;
drop table if exists archive;
drop table if exists status;
drop table if exists project;

#enumeration of archives
create table archive (
name varchar(10) not null,
full_name varchar(128),
primary key (name)
) ENGINE=InnoDB;

#enumeration of possible dataset states
create table status (
status varchar(10) not null,
primary key (status)
) ENGINE=InnoDB;

#project is a group that can create/own a reference epigenome (e.g. Blueprint, DEEP)
create table project (
project_id int(10) unsigned not null auto_increment,
name varchar(128) not null,
id_prefix varchar(10) not null,
primary key (project_id)
) ENGINE=InnoDB;

#dataset is an accession for a reference data set. all details bar the id & project can change and are in dataset_version
create table dataset (
dataset_id int(10) unsigned not null auto_increment,
project_id int(10) unsigned not null,
accession varchar(18),
primary key (dataset_id) ,
key(project_id),
key(accession),
foreign key (project_id) references project(project_id)
) ENGINE=InnoDB;

#the details of a dataset. can change, so expect a new one on each update
create table dataset_version (
dataset_version_id int(10) unsigned not null auto_increment,
dataset_id int(10) unsigned not null,
version int(4) unsigned not null,
is_current boolean not null,
local_name varchar(128),
description varchar(512),
full_accession varchar(20) not null,
status varchar(10) not null,
primary key (dataset_version_id),
key (dataset_id),
foreign key (dataset_id) references dataset(dataset_id),
key (status),
foreign key (status) references status(status),
unique key (full_accession),
key (dataset_id,version),
key (dataset_id,is_current)
) ENGINE=InnoDB;

#metadata used to describe the samples used in the dataset_version
create table meta_data (
meta_data_id int(10) unsigned not null auto_increment,
dataset_version_id int(10) unsigned not null,
name varchar(256) not null,
value varchar(4000) not null,
primary key (meta_data_id),
key(dataset_version_id),
foreign key (dataset_version_id) references dataset_version(dataset_version_id)
) ENGINE=InnoDB;

#raw data for a data set. points to archive entries. Most need a single id (primary accession), but this isn't sufficient for all cases so we have a secondary_accession 
create table raw_data (
raw_data_id int(10) unsigned not null auto_increment,
dataset_version_id int(10) unsigned not null,
primary_accession varchar(64) not null, 
secondary_accession varchar(64) not null,
archive varchar(10) not null,
archive_url varchar(512),
primary key (raw_data_id),
key(dataset_version_id),
foreign key (dataset_version_id) references dataset_version(dataset_version_id),
key(archive),
foreign key (archive) references archive(name),  
) ENGINE=InnoDB;


