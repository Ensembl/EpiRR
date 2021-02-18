import os, json, urllib
from stat import S_IREAD, S_IRGRP, S_IROTH
EPIRR1_DUMP = os.getenv("EPIRR1_DUMP")


# Satellite tables 
def add_archives(session, Archive):
    session.add(Archive(name="GEO", full_name="Gene Expression Omnibus", url="https://www.ncbi.nlm.nih.gov/geo/"))
    session.add(Archive(name="EGA", full_name="European Genome-phenome archive", url="https://www.ebi.ac.uk/ega/"))
    session.add(Archive(name="DDBJ", full_name="DNA Data Bank of Japan", url="https://www.ddbj.nig.ac.jp/index-e.html"))
    session.add(Archive(name="SRA", full_name="NCBI Sequence Read Archive", url="https://www.ncbi.nlm.nih.gov/sra"))
    session.add(Archive(name="ENA", full_name="European Nucelotide Archive", url="https://www.ebi.ac.uk/ena/"))
    session.add(Archive(name="JGA", full_name="Japanese Genotype-phenotype Archive", url="https://www.ddbj.nig.ac.jp/index-e.html"))
    session.add(Archive(name="ENCODE", full_name="Encyclopedia of DNA Elements", url="https://www.encodeproject.org/"))
    session.commit()


def add_projects(session, Project):
    session.add(Project(name="BLUEPRINT", url="https://www.blueprint-epigenome.eu/"))
    session.add(Project(name="NIH Roadmap Epigenomics", url="http://www.roadmapepigenomics.org/"))
    session.add(Project(name="DEEP", url="http://www.deutsches-epigenom-programm.de/"))
    session.add(Project(name="AMED-CREST", url="http://crest-ihec.jp/english/index.html"))
    session.add(Project(name="ENCODE", url="https://www.encodeproject.org/"))
    session.add(Project(name="Korea Epigenome Project (KNIH)", url="http://nih.go.kr/contents.es?mid=a50303010300"))
    session.add(Project(name="CEEHRC", url="http://www.epigenomes.ca/"))
    session.add(Project(name="GIS", url="https://www.a-star.edu.sg/gis/our-science/epigenetic-and-epitranscriptomic-regulation"))
    session.add(Project(name="EpiHK", url="https://epihk.org/"))
    session.commit()

def add_status(session, Status):
    session.add(Status(name="Complete"))
    session.add(Status(name="Partial"))
    session.commit()

def add_assay_type(session, Assay_type):
    session.add(Assay_type(name="ChIP-Seq"))
    session.add(Assay_type(name="RNA-Seq"))
    session.add(Assay_type(name="Bisulfite-Seq"))
    session.commit()

def add_ihec_version(session,Ihec_version):
    session.add(Ihec_version(version="1.0", url="https://github.com/IHEC/ihec-ecosystems/blob/master/docs/metadata/1.0/Ihec_metadata_specification.md"))
    session.add(Ihec_version(version="2.0", url="https://github.com/IHEC/ihec-ecosystems/blob/master/docs/metadata/2.0/Ihec_metadata_specification.md"))
    session.commit()

def fetch_epirr_viewall(url):
    """
    Fetch all EpiRR records in JSON. 
    Depending on the geo location, this can take a while
    Therefore results are stored in file
    
    """
    if os.path.isfile(EPIRR1_DUMP) and os.access(EPIRR1_DUMP, os.R_OK):
        with open(EPIRR1_DUMP) as f:
            return(json.load(f))
    else:
        epirr_entry_json = get_json_from_url(url)
        with open(EPIRR1_DUMP, 'w') as output:
            json.dump(epirr_entry_json, output)
        os.chmod(EPIRR1_DUMP, S_IREAD|S_IRGRP|S_IROTH) 
        return epirr_entry_json

def get_json_from_url(url):
    with urllib.request.urlopen(url) as all:
        return (json.loads(all.read().decode()))