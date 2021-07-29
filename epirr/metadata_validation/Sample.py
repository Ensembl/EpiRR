from Xml import Xml
import re
import json

class Sample(Xml):
    def __init__(self, xml, path_to_sra_xsd) -> None:
        super().__init__(xml, 'sample', path_to_sra_xsd)
        self._biomaterial_type = None
        self._sample_attributes = {}
        self._json = {}

        self._set_biomaterial_type()
        self._set_sample_attributes()

    @property
    def biomaterial_type(self):
        return self._
    
    @property
    def sample_attributes(self) -> str:
        return self._sample_attributes
    
    @property
    def json(self) -> json:
        return self.sample_attributes
    
    def _set_biomaterial_type(self) -> str:
        """Test and set biomaterial_type"""
        xpath = ".//SAMPLE_ATTRIBUTE[TAG='BIOMATERIAL_TYPE']/VALUE"
        try:
            biomaterial_type = self.etree.xpath(xpath)[0].text.lower()
        except:
            raise ValueError("BIOMATERIAL_TYPE missing")
        
        allowed = "^(cell line)$|^(primary cell)$|^(primary cell culture)$|^(primary tissue)$"
        if not re.search(allowed, biomaterial_type):
            raise ValueError(f"BIOMATERIAL_TYPE must match {allowed}, Found: {biomaterial_type}")
        self._biomaterial_type = biomaterial_type
    
    def _set_sample_attributes(self):
        """sample attributes"""
        # print(lxml.etree.tostring(self.etree, pretty_print = True).decode())

        attributes = self.etree.xpath(".//SAMPLE_ATTRIBUTES/*")
        print(attributes)
        for a in attributes:
            tag   = a.find("TAG").text.lower()
            value = a.find("VALUE").text.lower()
            print(f"{tag}\t{value}")

            self._sample_attributes[tag] = value