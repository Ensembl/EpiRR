import sys, os, psycopg2, mysql.connector
from mysql.connector import errorcode
from pprint import pprint

from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy import create_engine


EPIRR1_VIEW_ALL = os.getenv("EPIRR1_VIEW_ALL")
EPIRR1_HOST = os.getenv("EPIRR1_HOST")
EPIRR1_USER = os.getenv("EPIRR1_USER")
EPIRR1_PW = os.getenv("EPIRR1_PW")
EPIRR1_DB = os.getenv("EPIRR1_DB")

EPIRR2_HOST = os.getenv("EPIRR2_HOST")
EPIRR2_USER = os.getenv("EPIRR2_USER")
EPIRR2_PW = os.getenv("EPIRR2_PW")
EPIRR2_DB = os.getenv("EPIRR2_DB")

def connect_mysql():
    try:
        connection = mysql.connector.connect(
            host=EPIRR1_HOST, 
            user=EPIRR1_USER, 
            passwd=EPIRR1_PW, 
            db=EPIRR1_DB)

        if connection.is_connected():
            db_Info = connection.get_server_info()
            cursor = connection.cursor()
            cursor.execute("select database();")
            record = str(cursor.fetchone()[0])
            print(f"Connected to MySQL Server version {db_Info} - DB: {record}")
            return connection

    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
            print(f"Issues with user name {EPIRR1_USER} or password {EPIRR1_PW}")
        elif err.errno == errorcode.ER_BAD_DB_ERROR:
            print(f"Database{EPIRR1_DB} does not exist")
        else:
            print(err)
    else:
        connection.close()


def connect_postgres():
    try:
        connection = psycopg2.connect(
                        user     = EPIRR2_USER,
                        password = EPIRR2_PW,
                        host     = EPIRR2_HOST,
                        # port     = EPIRR2_PORT, <-- Not working
                        database = EPIRR2_DB)

        cursor = connection.cursor()
        # Print PostgreSQL Connection properties
        print ( connection.get_dsn_parameters(),"\n")

        # Print PostgreSQL version
        cursor.execute("SELECT version();")
        record = cursor.fetchone()
        print("You are connected to - ", record,"\n")

    except (Exception, psycopg2.Error) as error :
        print ("Error while connecting to PostgreSQL", error)
        sys.exit(1)

    return connection.cursor()





Base = automap_base()

db_string = "postgres://juettema:password@127.0.01:5432/epirr_3"
engine = create_engine(db_string, echo=True)
Session = sessionmaker(bind=engine)
session = Session()

# reflect the tables
Base.prepare(engine, reflect=True)

Epigenome                    = Base.classes.epigenome
Project                      = Base.classes.project
Epigenome_version            = Base.classes.epigenome_version
Status                       = Base.classes.status
Epigenome_version_experiment = Base.classes.epigenome_version_experiment
Experiment                   = Base.classes.experiment
Archive                      = Base.classes.archive
Experiment_type              = Base.classes.experiment_type
Library_strategy             = Base.classes.library_strategy
Experiment_metadata          = Base.classes.experiment_metadata
Experiment_sample            = Base.classes.experiment_sample
Sample                       = Base.classes.sample
Sample_metadata              = Base.classes.sample_metadata
Ihec_version                 = Base.classes.ihec_version



m_con = connect_mysql() 
m_cursor = m_con.cursor(dictionary=True)
# p_con = connect_postgres()
# p_cursor = p_con.cursor()



q_eg = "SELECT dataset_id, project.name AS project_name, accession, created FROM dataset JOIN project USING (project_id)"
q_dv = """SELECT dataset_version_id, version, is_current, description, full_accession, status.name, type.name, created FROM dataset_version JOIN type using (type_id) JOIN status USING status_id WHERE dataset_id = '%s'"""
m_cursor.execute(q_eg)
result = m_cursor.fetchall()

for r in result:
    pprint(r)
    print(r['accession'])
    project = session.query(Project).filter_by(name=r['project_name']).one()
    epigenome = Epigenome(accession=r['accession'], project_id = project.project_id, created_at=r['created'])
    session.add(epigenome)
    session.commit()
    m_cursor.execute(q_dv % (epigenome.epigenome_id))
    ds_versions = m_cursor.fetchall()
    pprint(r)

    # for dsv in ds_versions:
    # print(epigenome.epigenome_id)
# Migration

# 1.
# Select all from dataset, including PK & project name.
# Store each epigenome, get PK back.

# 2. select everything from dataset_version for PK


# session.add(Epigenome(accession="IHEC000000000001",description="A test",project_id="1",ihec_version_id="1",status_id="1"))
# session.add(Experiment(accession="exp1",archive_id=4,assay_type_id="2",ihec_version_id=2,xml="txt"))
# session.commit()

# add_archives(session, Archive)
# add_assay_type(session, Assay_type)
# add_status(session, Status)
# add_projects(session, Project)
# add_ihec_version(session,Ihec_version)

# session.add(Epigenome())
# session.commit()
