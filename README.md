# EpiRR

EpiRR is intended to act as a registry of reference epigenomes. Initial work has focused on storing references to archived raw data.

## Scope

EpiRR records the raw data that forms the basis of reference epigenomes, across several archives. 

## Submission

IHEC projects with epigenomes to register should mail blueprint-dcc@ebi.ac.uk to arrange submission. Submissions are accepted as text or JSON files via private FTP site. One file must be used per reference epigenome.

The minimal requirements for submission are
 - a valid project name
 - one or more pieces of raw data, available through a supported archive
 - consistent metadata attributes for samples referenced in the raw data
 - an experiment type, as per the IHEC metadata requirements 
 
Optionally, you can include any of the following:
 - a text description of your reference epigenome
 - your project's ID for the reference epigenome

The requirements for raw data vary depending on the archive, but in each case the archive name and experiment ID are required. For some archives, a secondary ID is also required. The requirements are listed in detail below.

Updates to a reference epigenome can be made by resubmission, including either the project local name, or the reference epigenome accession. Modifications result in an increase in the version number for the reference epigenome.

### Text format

Text file submissions must have the suffix `.refepi`. This format is intended for use by submitters preparing files by hand. Each line represents one property of the epigenome. Properties and values are tab separated. Line order is not important. Each file should contain a single reference epigenome.

    PROJECT	Example project
    LOCAL_NAME	ep_ref_1
    DESCRIPTION	classical monocytes from a male donor 
    RAW_DATA	GEO	GSM000001
    RAW_DATA	SRA	SRX000001
    RAW_DATA	ENA	ERX000001
    RAW_DATA	EGA	EGAX00000000001	EGAD00000000001

If you need to update a submission, add the EpiRR accession to the file:

    PROJECT	Example project
    ACCESSION	IHECRE00000001
    DESCRIPTION	classical monocytes from a male donor 
    RAW_DATA	GEO	GSM000001
    RAW_DATA	SRA	SRX000001
    RAW_DATA	ENA	ERX000001
    RAW_DATA	EGA	EGAX00000000001	EGAD00000000001

### JSON format

JSON file submissions must have the suffix `.refepi.json`. Semantics are the same as for the text format. Attribute names should be lower case. This format is intended for use by submitters preparing files programmatically. Each file should contain a single reference epigenome.

    {"project": "Example project",
    "local_name": "ep_ref_1",
    "description": "classical monocytes from a male donor", 
    "raw_data": [
     {"archive": "GEO", "primary_id": "GSM000001"},
     {"archive": "SRA", "primary_id": "SRX000001"},
     {"archive": "ERA", "primary_id": "ERX000001"},
     {"archive": "EGA", "primary_id": "EGAX00000000001", "secondary_id", "EGAD00000000001"}
    ]} 

###Attributes

The attributes required are common between both submission formats. The attribute name should be lower case for JSON file submission and upper case for 

 * PROJECT: Project name (required)
 * ACCESSION: EpiRR accession for the reference epigenome. Weither this or LOCAL\_NAME must be present for updates, must not be present in initial submission.
 * LOCAL\_NAME: ID for reference epigenome used within the project. Optional, either this or ACCESSION must be present for updates.
 * DESCRIPTION: Free text description of the reference epigenome. Optional.
 * RAW\_DATA: Archive name, primary ID, secondary ID. Details vary by archive. At least one required.


## Supported Projects

These project names are currently supported. Please get in touch if there are any omissions or errors.

 * BLUEPRINT
 * DEEP
 * EPP
 * NIH Roadmap Epigenomics
 * CREST
 * CEMT

## Supported Archives

Each archive has different requirements.


### [DDBJ SRA](http://trace.ddbj.nig.ac.jp/dra/index_e.html)

    Archive Name: DDBJ
    Primary ID: Experiment ID (e.g. ERX002125)
    Secondary ID: Not applicable

Due to relative access times from EMBL-EBI, we do not query DDBJ directly. As an INSDC archive, the data is shared with peers at EMBL-EBI and NCBI. There may be a small period of time between submission to DDBJ and the data being visible to EpiRR.

		
### [GEO](http://www.ncbi.nlm.nih.gov/geo/)

    Archive Name: GEO
    Primary ID: Experiment ID (e.g. GSM409307)
    Secondary ID: Not applicable

GEO supports array and sequence data. EpiRR supports both, although array data is not well tested. Please get in touch if you wish to register array data from GEO.

### [EGA](https://www.ebi.ac.uk/ega/)

    Archive Name: EGA
    Primary ID: Experiment ID (e.g. EGAX00001074437)
    Secondary ID: Dataset ID (e.g. EGAD00001000676)

The dataset must contain data for the experiment, and must be visible on the EGA website. We require formal permission to make use of metadata from your EGA account. Please get in touch with blueprint-dcc@ebi.ac.uk if you intend to submit references to data in this archive.

The code to access this archive is not included in the EpiRR github account, as it is not useful outside EBI.

While the EGA archives sequencing and array data, EpiRR only supports sequencing data at this time.

### [ENA SRA](https://www.ebi.ac.uk/ena)

    Archive Name: ENA
    Primary ID: Experiment ID (e.g. ERX002125)
    Secondary ID: Not applicable

### [NCBI SRA](www.ncbi.nlm.nih.gov/sra)

    Archive Name: SRA
    Primary ID: Experiment ID (e.g. SRX002125)
    Secondary ID: Not applicable

### [ArrayExpress](http://www.ebi.ac.uk/arrayexpress/)

    Archive Name: AE
    Primary ID: Experiment ID (e.g. E-GEOD-35522)
    Secondary ID: Sample ID (e.g. GSM870141 1)

ArrayExpress is supported, but has not been throughly tested. Please get in touch if you wish to reference data in ArrayExpress.

## Output

For each reference epigenome, two files will be produced during the submission process.

 * source_file_name.refepi.json.out
 * source_file_name.refepi.err
 
The .err file contains any error messages generated during the accession process. If the size of this file is greater than 0, accession process was not successful. Check the error file to understand the problems and revise the submission.

The .json.out file contains a representation of the reference epigenome, as stored in EpiRR. This includes the accession generated by EpiRR, and metadata gathered for the epigenome. Please review this to ensure the annotation meets your expectations.

##Metadata

EpiRR uses the experiment and sample metadata to annotate the reference epigenome. Epigenomes must be coherent and should follow the IHEC metadata guidelines.

Each experiment must have the EXPERIMENT_TYPE attribute.
Assay type is taken from the standard archive metadata (library strategy in SRA/ENA/EGA).

Each sample must have some minimal attributes:
 * BIOMATERIAL_TYPE
 * DONOR_ID or LINE
 * LINE, CELL\_TYPE or TISSUE\_TYPE.
Species is taken from the standard archived metadata and is required.

To annotate each reference epigenome, the sample metadata is compared. Attributes that are consistent across all referenced samples are used to annotate the epigenome. 'Consistent' means that the attribute names must be the same (although case can vary) and the values must be identical. 

To ensure coherence, the following minimal common meta data across an epigenome are required:
 * Species
 * BIOMATERIAL\_TYPE
 * LINE, CELL\_TYPE, TISSUE\_TYPE or DISEASE

This is not intended to form a full validator for the IHEC metadata, rather it is to ensure a minimum level of coherence within a reference epigenome.

## Access

We have a prototype REST interface, included in the github repo. This has not been deployed yet - this documentation will be updated when it has been done.

The REST interface will support the following use cases:

- fetch all current reference epigenomes
- fetch specific version of a reference epigenome, including historic versions
