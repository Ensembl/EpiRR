import lxml.etree

class Xml():
    def __init__(self, xml_doc: str, xml_type: str) -> None:
        self._xml = None
        self._etree = None
        self.xml = xml_doc
        self.etree = self.xml
        self.xml_type = xml_type

    @property
    def xml(self) -> str:
        return self._xml

    @xml.setter
    def xml(self, xml: str) -> None:
        self._xml = xml.strip()

    @property
    def etree(self) -> lxml.etree:
        return self._etree

    @etree.setter
    def etree(self, xml: str) -> None:
        try:
            self._etree = lxml.etree.fromstring(xml.encode('utf-8'))
        except lxml.etree.ParseError:
            raise ValueError("Invalid XML")

    # @property
    # def type(self) -> str:
    #     return self._type

    # @type.setter
    # def type(self, etree) -> None:
    #     if etree.xpath('/EXPERIMENT_SET'):
    #         self._type = 'experiment'
    #     elif etree.xpath('/SAMPLE_SET'):
    #         self._type = 'sample'
    #     else:
    #         raise ValueError('<EXPERIMENT_SET> or <SAMPLE_SET> must be the first element')
        


    # @property
    # def schema_url(self) -> str:
    #     return self._schema_url
    
    # @schema_url.setter
    # def schema_url(self, schema_url: str) -> None:
    #     if not validators.url(schema_url):
    #         return("Invalid URL")
    #     self._schema_url = schema_url

    ls = {}
    ls["DNase-Hypersensitivity"] = "chromatin_accessibility"
    ls["ATAC-seq"] = "chromatin_accessibility" 
    ls["NOME-Seq"] = "chromatin_accessibility"
    ls["Bisulfite-Seq"] = "bisulfite-seq"
    ls["MeDIP-Seq"] = "medip-seq"
    ls["MRE-Seq"] = "mre-seq"
    ls["ChIP-Seq"] = "chip-seq"
    ls["RNA-Seq"] = "rna-seq"
    ls["miRNA-Seq"] = "rna-seq"
    ls["WGS"] = "wgs"


""" 
     url_ihec_schema = "https://raw.githubusercontent.com/IHEC/ihec-ecosystems/master/schemas/json/2.0/experiment.json"

    XML is tested and stored as json
    1. Test if object is XML
    2. Test if object is Experiment or Sample
    3. Run SRA validation 
    4. Experi 
    5. Convert to and return JSON
"""

    # def __init__(self,  xml):
    #     self._xml  = xml.strip()
    #     self._remove_declaration_line()
    #     self._type = None
    #     self._etree = None
    #     self._set_etree()
    #     self._set_type()
    #     self.sra_xsd = {}
    #     self.sra_xsd['experiment'] = 'xsd/SRA.experiment.xsd'
    #     self.sra_xsd['sample']     = 'xsd/SRA.sample.xsd'
    #     self._validate_sra()
    #     self._test()
    #     self._json = None
    #     self._set_json()

    # def _remove_declaration_line(self):

    #     """XML schema """
    #     return
    #     self._xml = re.sub('^<\?xml version.*>', '', self._xml)


        
    
    # def _set_type(self):
    #     if self._etree.xpath('/EXPERIMENT_SET'):
    #         self._type = 'experiment'
    #     elif self._etree.xpath('/SAMPLE_SET'):
    #         self._type = 'sample'
    #     else:
    #         raise ValueError('<EXPERIMENT_SET> or <SAMPLE_SET> must be the first element')

    # def _validate_sra(self):
    #     # print(type(self._etree))
    #     # byte_str =  self._etree.encode('utf-8')
    #     schemaDoc = lxml.etree.parse(self.sra_xsd[self._type])
    #     schema    = lxml.etree.XMLSchema(schemaDoc)
    #     if not schema.validate(self._etree):
    #     # if not schema.validate(byte_str):
    #         raise ValueError('Incopatible with SRA schema')

    # def _test(self):
    #     if self._type == 'experiment':
    #         self._verify_library_strategy()


    # def _verify_library_strategy(self):
    #     # xpath = ".//EXPERIMENT_ATTRIBUTE/TAG[text()='EXPERIMENT_TYPE']/following-sibling::VALUE"

    #     xpath = ".//LIBRARY_STRATEGY"
    #     library_strategy = self._etree.xpath(xpath)[0].text
    #     terms = ["DNase-Hypersensitivity", "ATAC-seq", "NOME-Seq", "Bisulfite-Seq", "MeDIP-Seq", "MRE-Seq", "ChIP-Seq", "WGS"]

    #     if library_strategy not in terms:
    #         raise ValueError(f"LIBRARY_STRATEGY must be one of {terms}")

    # def _set_json(self):
    #     self._json = xmltodict.parse(self._xml)  
    #     print(type(self._json))
         
    # @property
    # def json(self):
    #     return self._json

    # def _somename(self):
    #     d = {}
    #     d['reference_registry_id'] = ''
    #     d['qc_flags'] = ''
    #     d['experiment_type'] = '/EXPERIMENT/EXPERIMENT_ATTRIBUTES/EXPERIMENT_ATTRIBUTE/TAG'
    #     d['experiment_ontology_curie'] = ''
    #     d['library_strategy'] = ''
    #     d['molecule_ontology_curie'] = ''
    #     d['molecule'] = ''
    #     d['extraction_protocol'] = ''
    #     d['dnase_protocol'] = ''
    #     d[''] = ''