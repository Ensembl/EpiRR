import re, xmltodict, json, sys
from lxml.etree import parse, XMLSchema, fromstring
from collections import defaultdict



class XmlTest:
    """ 
    1. Test if incoming file is XML
    2. Test if Experiment or Sample
    3. Run SRA validation for
    4. Convert to and return JSON
    """
    def __init__(self, xml_string):
        self.xml_string = xml_string.strip()
        self.sra_xsd = {}
        self.sra_xsd['experiment'] = 'xsd/SRA.experiment.xsd'
        self.sra_xsd['sample']     = 'xsd/SRA.sample.xsd'
        self.type = None

    def check_xml_identify_type(self):
        s1 = '<?xml version'
        s2 = '<EXPERIMENT_SET>'
        s3 = '<SAMPLE_SET>'

        if not re.match(rf"{s1}|{s2}|{s3}", self.xml_string, re.IGNORECASE):
            raise ValueError('Invalid XML')

        if re.search(s2,self.xml_string, re.IGNORECASE):
            self.type = 'experiment'
        elif re.search(s3,self.xml_string, re.IGNORECASE):
            self.type = 'sample'
        else:
            raise ValueError('Not an EXPERIMENT or SAMPLE')

    def validate(self):
        tree      = fromstring(self.xml_string)
        schemaDoc = parse(self.sra_xsd[self.type])
        schema    = XMLSchema(schemaDoc)
        if schema.validate(tree):
            print('XML validated')
        else:
            print(schema.error_log)
            raise ValueError('XML NOT validated')
    
    def convert_xml_to_json(self):
        return xmltodict.parse(self.xml_string)
        return json.dumps(xmltodict.parse(self.xml_string))
