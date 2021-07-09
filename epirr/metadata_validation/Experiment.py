from Xml import Xml
from pprint import pprint
import lxml.etree
import json

class Experiment(Xml):
    def __init__(self, xml) -> None:
        super().__init__(xml, 'experiment')
        self._library_strategy = None
        self._experiment_type = None
        self._experiment_attributes = {}
        self._sample_accession = None
        self._sra_passed = False
        self._ihec_version = []
        self._json = {}
        self._libary_strategy_to_experiment_type = {}
        
        self._libary_strategy_to_experiment_type
        self.library_strategy = self.etree
        self.experiment_type = self.etree
        self.experiment_attributes = self.etree
        self.sample_accession = self.etree


    @property
    def libary_strategy_to_experiment_type(self):
        return self._libary_strategy_to_experiment_type

    @libary_strategy_to_experiment_type.setter
    def libary_strategy_to_experiment_type(self):
        self._libary_strategy_to_experiment_type["dnase-hypersensitivity"] = "chromatin_accessibility"
        self._libary_strategy_to_experiment_type["atac-seq"] = "chromatin_accessibility" 
        self._libary_strategy_to_experiment_type["nome-seq"] = "chromatin_accessibility"
        self._libary_strategy_to_experiment_type["bisulfite-seq"] = "bisulfite-seq"
        self._libary_strategy_to_experiment_type["medip-seq"] = "medip-seq"
        self._libary_strategy_to_experiment_type["mre-seq"] = "mre-seq"
        self._libary_strategy_to_experiment_type["chip-seq"] = "chip-seq"
        self._libary_strategy_to_experiment_type["rna-seq"] = "rna-seq"
        self._libary_strategy_to_experiment_type["mirna-seq"] = "rna-seq"
        self._libary_strategy_to_experiment_type["wgs"] = "wgs"

    @property
    def library_strategy(self) -> str:
        return self._library_strategy
    
    @library_strategy.setter
    def library_strategy(self, etree) -> str:
        if etree.xpath(".//LIBRARY_STRATEGY"):
            ls = etree.xpath(".//LIBRARY_STRATEGY")[0].text.lower()
            print(self.libary_strategy_to_experiment_type)
            if ls in self.libary_strategy_to_experiment_type.keys():
                self._library_strategy = ls
            else:
                raise ValueError(f"LIBRARY_STRATEGY '{ls}'' invalid. One of {self.libary_strategy_to_experiment_type.keys()}")
        else:
            raise ValueError("LIBRARY_STRATEGY not defined")
    
    @property
    def experiment_type(self) -> str:
        return self._experiment_type
    
    @experiment_type.setter
    def experiment_type(self, etree) -> str:
        xpath = ".//EXPERIMENT_ATTRIBUTE[TAG='EXPERIMENT_TYPE']/VALUE"
        self._experiment_type = etree.xpath(xpath)[0].text.lower()
    
    @property
    def sample_accession(self) -> str:
       return self._sample_accession
    
    @sample_accession.setter
    def sample_accession(self, etree) -> str:
        """Sample accession"""
        if etree.xpath(".//SAMPLE_DESCRIPTOR")[0].get("accession"):
            self._sample_accession = etree.xpath(".//SAMPLE_DESCRIPTOR")[0].get("accession").lower()
        elif etree.xpath(".//DESIGN/SAMPLE_DESCRIPTOR/IDENTIFIERS/PRIMARY_ID"):
            self._sample_accession = etree.xpath(".//DESIGN/SAMPLE_DESCRIPTOR/IDENTIFIERS/PRIMARY_ID")[0].text.lower()
        else:
            raise ValueError("No linked Sample found")

    @property
    def experiment_attributes(self) -> str:
        return self._experiment_attributes
    
    @experiment_attributes.setter
    def experiment_attributes(self, etree) -> str:
        """Experiment attributes. Store lowercase"""
        attributes = etree.xpath(".//EXPERIMENT_ATTRIBUTES/*")
        for a in attributes:
            self._experiment_attributes[a.find("TAG").text.lower()] = a.find("VALUE").text.lower()
    
    @property
    def json(self) -> json:
        return {f'"library_strategy": {self.library_strategy},{self.experiment_attributes}'}
    

        

        