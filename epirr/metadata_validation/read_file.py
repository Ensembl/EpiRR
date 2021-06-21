import sys, getopt, xmltodict, json
from XmlTest import XmlTest

def main(argv):
    inputfile = ''
    try:
        opts, args = getopt.getopt(argv,"hi:",["ifile="])
    except getopt.GetoptError:
        print ('test.py -i <inputfile>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print ('test.py -i <inputfile>')
            sys.exit()
        elif opt in ("-i", "--ifile"):
            inputfile = arg
        else:
            print ('test.py -i <inputfile>')
            sys.exit()
            
    with open(inputfile, 'r') as file:
        return file.read()
   

def parse(file):
        parser = None
        # find parser
        try:
            from lxml.etree import parse, XMLSchema, fromstring
            print('using lxml.etree parser')
            # parse XML and validate it
            tree = fromstring(file)
            # get XSD
            schemaDoc = parse('xsd/SRA.sample.xsd')
            schema = XMLSchema(schemaDoc)
            if schema.validate(tree):
                print('XML validated')
                return tree
            print(schema.error_log)
            raise ValueError('XML NOT validated')
        except ImportError:
            try:
                from xml.etree.ElementTree import fromstring
                print('using xml.etree.ElementTree parser')
                return fromstring(file)
            except ImportError:
                print("Failed to import ElementTree from any known place")
                raise 


if __name__ == "__main__":
    file = main(sys.argv[1:])
    xml_test = XmlTest(file)
    xml_test.check_xml_identify_type()
    xml_test.validate()
    o = xml_test.convert_xml_to_json()
    print(type(o))
    print(json.dumps(o,indent=4))
