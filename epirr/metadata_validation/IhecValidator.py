import collections
import lxml.etree
import traceback
import json
import requests
from urllib.request import urlopen
from urllib.error import URLError, HTTPError
import collections 



class IhecValidator():
    def __init__(self, type: str) -> None:
        self._type = type
        self._config_url = 'https://raw.githubusercontent.com/Ensembl/EpiRR/epirr_2.0/epirr/metadata_validation/config.json'
        self._config = collections.OrderedDict
        self._xml_parser = None
        self._schema = None

        self._test_type()
        self._fetch_config()
        self._initiate_xml_parser()
        self._create_xml_schema_object()

    @property
    def type(self):
        return self._type

    @property
    def config_url(self):
        return self._config_url

    @property
    def config(self):
        return self._config
    
    @property
    def schema(self):
        return self._schema
        
    
    def _test_type(self):
        if self._type not in {'experiment', 'sample'}:
            raise ValueError(f"Type must be experiment or sample, not {self.type}")
    
    def _fetch_config(self):
        try:
            self._config = collections.OrderedDict(json.loads(requests.get(self.config_url).text))
        except Exception as e:
            raise f"Error fetching Congfig: {e}"

    def _initiate_xml_parser(self):
        try:
            self._xml_parser = lxml.etree.XMLParser(ns_clean=True,remove_comments=True,remove_pis=True)
        except Exception as e:
            raise f"Could not initiate XMLParser '{e}'"

    def _create_xml_schema_object(self):
        try:
            self._schema =  lxml.etree.XMLSchema(self._load_sra_xsd())
        except :
            raise(f"Error {lxml.etree.XMLSchema.error_log}")

    def _load_sra_xsd(self):
        try:
            return lxml.etree.fromstring(self._fetch_sra_xsd())
        except IOError:
            raise IOError(f"File '{self.config['sra'][self.type]}' not accessible")

    def _fetch_sra_xsd(self):
        try:
            return urlopen(self.config['sra'][self.type]).read()
        except HTTPError as e:
            raise HTTPError(f"Error code: {e.code}")
        except URLError as e:
            raise URLError(f"Reason: {e.code}")

    def validate_sra(self, etree: lxml.etree):
        try:
            return self.schema.assertValid(etree)
        except lxml.etree.DocumentInvalid as e:
            raise ValueError(f"SRA validation error: {e}")
        except Exception as e:
            traceback.print_exc()
