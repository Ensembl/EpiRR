from Xml import Xml
from pprint import pprint
import lxml.etree
import json
import re

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

        self._set_libary_strategy_to_experiment_type()
        self._set_library_strategy()
        self._set_experiment_type()
        self._set_experiment_attributes()
        self._set_sample_accession()


    @property
    def libary_strategy_to_experiment_type(self):
        return self._libary_strategy_to_experiment_type

    @property
    def library_strategy(self) -> str:
        return self._library_strategy
    
    @property
    def experiment_type(self) -> str:
        return self._experiment_type
    @property
    def sample_accession(self) -> str:
       return self._sample_accession

    @property
    def experiment_attributes(self) -> str:
        return self._experiment_attributes

    @property
    def json(self) -> json:
        return {f'"library_strategy": {self._set_library_strategy},{self.experiment_attributes}'}


    def _set_library_strategy(self):
        if self.etree.xpath(".//LIBRARY_STRATEGY"):
            ls = self.etree.xpath(".//LIBRARY_STRATEGY")[0].text.lower()
            if ls in self.libary_strategy_to_experiment_type.keys():
                self._library_strategy = ls
            else:
                raise ValueError(f"LIBRARY_STRATEGY '{ls}'' invalid. One of {self.libary_strategy_to_experiment_type.keys()}")
        else:
            raise ValueError("LIBRARY_STRATEGY not defined")
    
    def _set_experiment_type(self):
        xpath = ".//EXPERIMENT_ATTRIBUTE[TAG='EXPERIMENT_TYPE']/VALUE"
        exp_type = self.etree.xpath(xpath)[0].text.lower()
        expected_exp_type_regex = self._libary_strategy_to_experiment_type[self.library_strategy]
        if not re.search(expected_exp_type_regex,exp_type):
            raise ValueError(f"EXPERIMENT_TYPE must match '{expected_exp_type_regex}''. Found: '{exp_type}'")
        self._experiment_type = exp_type
    
    def _set_sample_accession(self):
        """Sample accession"""
        if self.etree.xpath(".//SAMPLE_DESCRIPTOR")[0].get("accession"):
            self._sample_accession = self.etree.xpath(".//SAMPLE_DESCRIPTOR")[0].get("accession").lower()
        elif self.etree.xpath(".//DESIGN/SAMPLE_DESCRIPTOR/IDENTIFIERS/PRIMARY_ID"):
            self._sample_accession = self.etree.xpath(".//DESIGN/SAMPLE_DESCRIPTOR/IDENTIFIERS/PRIMARY_ID")[0].text.lower()
        else:
            raise ValueError("No linked Sample found")

    def _set_experiment_attributes(self):
        """Experiment attributes"""
        attributes = self.etree.xpath(".//EXPERIMENT_ATTRIBUTES/*")
        for a in attributes:
            self._experiment_attributes[a.find("TAG").text.lower()] = a.find("VALUE").text.lower()

    def _set_libary_strategy_to_experiment_type(self):
        ""
        self._libary_strategy_to_experiment_type["dnase-hypersensitivity"] = "^chromatin accessibility$"
        self._libary_strategy_to_experiment_type["atac-seq"] = "^chromatin accessibility$" 
        self._libary_strategy_to_experiment_type["nome-seq"] = "^chromatin accessibility$"
        self._libary_strategy_to_experiment_type["bisulfite-seq"] = "^dna methylation$"
        self._libary_strategy_to_experiment_type["medip-seq"] = "^dna methylation$"
        self._libary_strategy_to_experiment_type["mre-seq"] = "^dna methylation$"
        self._libary_strategy_to_experiment_type["chip-seq"] = "^(chip-seq input)$|^(histone h\\w+([\\./]\\w+)?)+$|^(transcription factor)$"
        self._libary_strategy_to_experiment_type["rna-seq"] = "^(rna-seq)$|^(mrna-seq)$|^(smrna-seq)$|^(total-rna-seq)$"
        self._libary_strategy_to_experiment_type["mirna-seq"] = "^(rna-seq)$|^(mrna-seq)$|^(smrna-seq)$|^(total-rna-seq)$"
        self._libary_strategy_to_experiment_type["wgs"] = "^wgs$"
    

        

        