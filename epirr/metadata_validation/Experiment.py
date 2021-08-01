from Xml import Xml
import json
import re
import copy

class Experiment(Xml):
    def __init__(self, xml: str, path_to_sra_xsd: str) -> None:
        super().__init__(xml, 'experiment', path_to_sra_xsd)
        self._library_strategy = None
        self._experiment_type = None
        self._experiment_attributes = {}
        self._sample_accession = None
        self._ihec_version = []
        self._json = {}
        self._libary_strategy_to_experiment_type = {}
        self._mandatory_values_xpath = {}

        self._set_libary_strategy_to_experiment_type()
        self._set_mandatory_values_xpath()
        self._test_all_manadory_elements()
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
    def mandatory_elements_xpath(self) -> dict:
        return self._mandatory_values_xpath
    

    @property
    def json(self) -> json:
        object = copy.deepcopy(self.experiment_attributes)
        object['library_strategy'] = self.library_strategy
        return object

    def _set_library_strategy(self):
        ls = self.etree.xpath(self._mandatory_values_xpath["library_strategy"])[0].text.lower()
        if ls in self.libary_strategy_to_experiment_type.keys():
            self._library_strategy = ls
        else:
            raise ValueError(f"LIBRARY_STRATEGY '{ls}'' invalid. One of {self.libary_strategy_to_experiment_type.keys()}.")

    
    def _set_experiment_type(self):
        exp_type = self.etree.xpath(self._mandatory_values_xpath['experiment_type'])[0].text.lower()
        expected_exp_type_regex = self._libary_strategy_to_experiment_type[self.library_strategy]
        if not re.search(expected_exp_type_regex,exp_type):
            raise ValueError(f"EXPERIMENT_TYPE must match '{expected_exp_type_regex}''. Found: '{exp_type}'")
        self._experiment_type = exp_type
    
    def _set_sample_accession(self):
        """Sample accession. Can be stored in 2 locations"""
        xpath_1 = self._mandatory_values_xpath["sample_descriptor"]
        xpath_2 = ".//DESIGN/SAMPLE_DESCRIPTOR/IDENTIFIERS/PRIMARY_ID"
        if self.etree.xpath(xpath_1)[0].get("accession"):
            self._sample_accession = self.etree.xpath(xpath_1)[0].get("accession").lower()
        elif self.etree.xpath(xpath_2):
            self._sample_accession = self.etree.xpath(xpath_2)[0].text.lower()
        else:
            raise ValueError("No linked Sample found or more than 1")

    def _set_experiment_attributes(self):
        """Experiment attributes"""
        attributes = self.etree.xpath(".//EXPERIMENT_ATTRIBUTES/*")
        for a in attributes:
            self._experiment_attributes[a.find("TAG").text.lower()] = a.find("VALUE").text.lower()
            
    def _test_all_manadory_elements(self):
        for key, xpath in self.mandatory_elements_xpath.items():
            self._test_manadory_elements(xpath)
    
    def _test_manadory_elements(self, xpath):
        element = self.etree.xpath(xpath)
        if not element:
            raise ValueError(f"Missing element: 'EXPERIMENT_TYPE'")
        if len(element) != 1:
            raise ValueError(f"Expected 1 EXPERIMENT_TYPE. Found: {len(element)}")

    def _set_mandatory_values_xpath(self):
        self._mandatory_values_xpath['experiment_type']   = ".//EXPERIMENT_ATTRIBUTE[TAG='EXPERIMENT_TYPE']/VALUE"
        self._mandatory_values_xpath["library_strategy"]  = ".//LIBRARY_STRATEGY"
        self._mandatory_values_xpath["sample_descriptor"] = ".//SAMPLE_DESCRIPTOR"


    def _set_libary_strategy_to_experiment_type(self):
        ""
        self._libary_strategy_to_experiment_type["dnase-hypersensitivity"] = "^chromatin accessibility$"
        self._libary_strategy_to_experiment_type["atac-seq"] = "^chromatin accessibility$" 
        self._libary_strategy_to_experiment_type["nome-seq"] = "^chromatin accessibility$"
        
        self._libary_strategy_to_experiment_type["bisulfite-seq"] = "^dna methylation$"
        self._libary_strategy_to_experiment_type["medip-seq"] = "^dna methylation$"
        self._libary_strategy_to_experiment_type["mre-seq"] = "^dna methylation$"
        
        self._libary_strategy_to_experiment_type["rna-seq"] = "^(rna-seq)$|^(mrna-seq)$|^(smrna-seq)$|^(total-rna-seq)$"
        self._libary_strategy_to_experiment_type["mirna-seq"] = "^(rna-seq)$|^(mrna-seq)$|^(smrna-seq)$|^(total-rna-seq)$"

        self._libary_strategy_to_experiment_type["chip-seq"] = "^(chip-seq input)$|^(histone h\\w+([\\./]\\w+)?)+$|^(transcription factor)$"

        self._libary_strategy_to_experiment_type["wgs"] = "^wgs$"
    
