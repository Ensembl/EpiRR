import sys, getopt, xmltodict, json, requests
from XmlTest import XmlTest
from collections import OrderedDict

 
   
def read_file(ifile):
    with open(ifile, 'r') as file:
        return file.read()

def get_options(argv):
    ifile = ''  
    ofile = f'{sys.argv[0]}.out.json'
    try:
        opts, args = getopt.getopt(argv,"hi:o:",["ifile=","ofile="])
    except getopt.GetoptError:
        print ('test.py -i <inputfile> -o <outputfile>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print ('test.py -i <inputfile> -o <outputfile>')
            sys.exit()
        elif opt in ("-i", "--ifile"):
            ifile = arg
        elif opt in ("-o", "--ofile"):
            ofile = arg
        else:
            print ('test.py -i <inputfile> -o <outputfile>')
            sys.exit()
    return ifile, ofile

def create_post_request(object, ofile):
    """

    """
    url_schema_experiment = 'https://raw.githubusercontent.com/IHEC/ihec-ecosystems/master/schemas/json/2.0/experiment.json'
    url_schema_sample = 'https://raw.githubusercontent.com/IHEC/ihec-ecosystems/master/schemas/json/2.0/experiment.json'


    schema_experiment =  OrderedDict(json.loads(requests.get(url_schema_experiment).text))
    schema_sample = OrderedDict(json.loads(requests.get(url_schema_sample).text))

    input = OrderedDict()
    input['schema'] = schema_experiment
    input['object'] = object
    with open(ofile,mode='w',) as f:
        f.write(json.dumps(input))

    # print(type(schema_experiment))
    # print(type(object))
    # print(type(input))

def get_schema(url):
    return OrderedDict(json.loads(requests.get(url).text))


if __name__ == "__main__":
    ifile, ofile = get_options(sys.argv[1:])
    # main(sys.argv[1:])
    xml = read_file(ifile)
    xml_test = XmlTest(xml)

    # xml_test.validate()
    o = xml_test.convert_xml_to_json()
    create_post_request(o, ofile)
    # # print(type(o))
    # # print(json.dumps(o,indent=4))
