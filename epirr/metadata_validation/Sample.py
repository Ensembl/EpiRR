from Xml import Xml
import lxml.etree
import re


from pprint import pprint

class Sample(Xml):
    def __init__(self, xml) -> None:
        super().__init__(xml, 'sample')
        self._biomaterial_type = None
        self._sample_attributes = {}
        
        self.json = {}

        self._set_biomaterial_type()
        self._set_sample_attributes()

    @property
    def biomaterial_type(self):
        return self._biomaterial_type
    
    @property
    def json(self) -> json:
        return {self.sample_attributes}
    
    def _set_biomaterial_type(self, etree: lxml.etree) -> str:
        """Test and set biomaterial_type"""
        allowed = "^(cell line)$|^(primary cell)$|^(primary cell culture)$|^(primary tissue)$"
        xpath = ".//SAMPLE_ATTRIBUTE[TAG='BIOMATERIAL_TYPE']/VALUE"
        try:
            biomaterial_type = etree.xpath(xpath)[0].text.lower()
        except:
            raise ValueError("BIOMATERIAL_TYPE missing")
        if not re.search(allowed, biomaterial_type):
            raise ValueError(f"BIOMATERIAL_TYPE must match {allowed}, Found: {biomaterial_type}")
        self._biomaterial_type = biomaterial_type
    
    def _set_sample_attributes(self):
        """sample attributes"""
        attributes = self.etree.xpath(".//sample_ATTRIBUTES/*")
        for a in attributes:
            self._sample_attributes[a.find("TAG").text.lower()] = a.find("VALUE").text.lower()