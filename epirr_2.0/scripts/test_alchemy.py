from sqlalchemy import create_engine, Base
from sqlalchemy import Table, Column, String, MetaData
from sqlalchemy.sql.sqltypes import VARCHAR, Integer, Text, Float, Enum, DateTime
import enum



class Epigenome(Base):
    __tablename__ = 'epigenome'

    epigenome_id    = Column(Integer, primary_key=True)
    accession       = Column(VARCHAR)
    description     = Column(Text)
    status_id       = Column(Integer)
    project_id      = Column(Integer)
    ihec_version_id = Column(Integer)
    created_at      = Column(DateTime)
    updated_at      = Column(DateTime)

class Experiment(Base):
    __tablename__ = "experiment"

    experiment_id    = Column(Integer, primary_key=True)
    accession        = Column(VARCHAR)
    archive_id       = Column(Integer)
    assay_type_id    = Column(VARCHAR)
    project_id       = Column(Integer)
    ihec_version_id  = Column(Integer)
    uri              = Column(VARCHAR)
    xml_uri          = Column(Text)
    md5sum           = Column(VARCHAR)
    validator_report = Column(Text)
    created_at       = Column(DateTime)
    updated_at       = Column(DateTime)

class Sample(Base):
    __tablename__ = "sample"
    sample_id        = Column(Integer, primary_key=True)
    accession        = Column(VARCHAR)
    ihec_version_id  = Column(Integer)
    xml              = Column(Text)
    uri              = Column(VARCHAR)
    md5sum           = Column(VARCHAR)
    validator_report = Column(Text)
    created_at       = Column(DateTime)
    updated_at       = Column(DateTime)

class Project(Base):
    __tablename__ = "project"
    project_id  = Column(Integer, primary_key=True)
    name        = Column(VARCHAR)

class Status(Base):
    __tablename__ = "status"
    status_id   = Column(Integer, primary_key=True)
    name        = Column(VARCHAR)



db_string = "postgres://juettema:password@127.0.01:5432/epirr_3"
db = create_engine(db_string)
meta = MetaData(db) 
archive_table = Table('archive', meta,
                        Column('name', VARCHAR),
                        Column('full_name', VARCHAR),
                        Column('url', VARCHAR))

with db.connect() as conn:
    insert_statement = archive_table.insert().values(
                        name="GEO",
                        full_name="Gene Expression Omnibus",
                        url="https://www.ncbi.nlm.nih.gov/geo/")
    conn.execute(insert_statement)

