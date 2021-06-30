import re, xmltodict, json,sys
# from lxml.etree import parse, XMLSchema, fromstring
# import xml.etree.ElementTree as etree
import lxml.etree 
from typing import List


class XmlTest:
    """ 
    1. Test if object is XML
    2. Test if object is Experiment or Sample
    3. Run SRA validation 
    4. Experi 
    5. Convert to and return JSON
    """
    def __init__(self,  xml):
        self._xml  = xml.strip()
        self._remove_declaration_line()
        self._type = None
        self._etree = None
        self._set_etree()
        self._set_type()
        self.sra_xsd = {}
        self.sra_xsd['experiment'] = 'xsd/SRA.experiment.xsd'
        self.sra_xsd['sample']     = 'xsd/SRA.sample.xsd'
        self._validate_sra()
        self._test_experiment()

    def _remove_declaration_line(self):
        self._xml = re.sub('^<\?xml version.*\n', '', self._xml)

    def _set_etree(self):
        try:
            self._etree =  lxml.etree.fromstring(self._xml)
        except lxml.etree.ParseError:
            raise ValueError("Invalid XML")
    
    def _set_type(self):
        if self._etree.xpath('/EXPERIMENT_SET'):
            self._type = 'experiment'
        elif self._etree.xpath('/SAMPLE_SET'):
            self._type = 'sample'
        else:
            raise ValueError('<EXPERIMENT_SET> or <SAMPLE_SET> must be the first element')

    def _validate_sra(self):
        schemaDoc = lxml.etree.parse(self.sra_xsd[self._type])
        schema    = lxml.etree.XMLSchema(schemaDoc)
        if not schema.validate(self._etree):
            raise ValueError('Incopatible with SRA schema')


    def _test_experiment(self):
        # xpath = ".//EXPERIMENT_ATTRIBUTE/TAG[text()='EXPERIMENT_TYPE']/following-sibling::VALUE"
        xpath = ".//LIBRARY_STRATEGY"
        library_strategy = self._etree.xpath(xpath)[0].text
        terms = ["DNase-Hypersensitivity", "ATAC-seq", "NOME-Seq", "Bisulfite-Seq", "MeDIP-Seq", "MRE-Seq", "ChIP-Seq", "WGS"]

        if library_strategy not in terms:
            raise ValueError(f"LIBRARY_STRATEGY must be one of {terms}")

        # if self._etree.xpath(xpath):
        #     vals: List[self._etree.Element] = self._etree.xpath(xpath)
        #     if  
        
        
        # try:
        #     self._etree.findtext('EXPERIMENT/EXPERIMENT_ATTRIBUTES/EXPERIMENT_ATTRIBUTE/TAG','EXPERIMENT_TYPE')
        # except Exception as inst:
        #     print(type(inst))    # the exception instance
        #     print(inst.args)     # arguments stored in .args
        #     print(inst)
            
    def convert_xml_to_json(self):
        return xmltodict.parse(self._xml)
        return json.dumps(xmltodict.parse(self.xml_string))


