import sys, getopt, xmltodict, json, requests
from collections import OrderedDict
from pprint import pprint

def read_file(ifile):
    with open(ifile, 'r') as file:
        return file.read()

def get_options(argv):
    ifile = ''  
    ofile = f'{sys.argv[0]}.out.json'
    sra_schema = ''
    try:
        opts, args = getopt.getopt(argv,"hi:o:s:",["ifile=","ofile=","sra="])
    except getopt.GetoptError:
        print ('test.py -i <inputfile> -o <outputfile> -s <path_to_sra_xsd>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print ('test.py -i <inputfile> -o <outputfile> -s <path_to_sra_xsd>')
            sys.exit()
        elif opt in ("-i", "--ifile"):
            ifile = arg
        elif opt in ("-o", "--ofile"):
            ofile = arg
        elif opt in ("-s", "--ofile"):
            sra_schema = arg
        else:
            print ('test.py -i <inputfile> -o <outputfile>')
            sys.exit()
    return ifile, ofile, sra_schema

# def create_post_request(object, ofile):
#     """

#     """
#     url_schema_experiment = 'https://raw.githubusercontent.com/Ensembl/EpiRR/epirr_2.0/epirr/metadata_validation/files/experiment_schema_new.json'
#     # url_schema_sample = 'https://raw.githubusercontent.com/IHEC/ihec-ecosystems/master/schemas/json/2.0/sample.json'


#     schema_experiment =  OrderedDict(json.loads(requests.get(url_schema_experiment).text))
#     # schema_sample = OrderedDict(json.loads(requests.get(url_schema_sample).text))

#     input = OrderedDict()
#     input['schema'] = schema_experiment
#     input['object'] = object
#     with open(ofile,mode='w',) as f:
#         f.write(json.dumps(input,indent=4))

#     # print(type(schema_experiment))
#     # print(type(object))
#     # print(type(input))

# def get_schema(url):
#     return OrderedDict(json.loads(requests.get(url).text))


if __name__ == "__main__":
    from Xml import Xml
    from Experiment import Experiment

    ifile, ofile, sra_schema = get_options(sys.argv[1:])
    xml = read_file(ifile)
    try:
        x = Experiment(xml, sra_schema)
    except Exception as e:
        print(f"Eror: '{e}'")
        sys.exit(1)
    print(x.library_strategy)
    print(x.experiment_type)
    print(x.sample_accession)
    pprint(x.experiment_attributes)
    print(type(x.json))
    print(x.json)
    print(json.dumps(x.json,indent=4))
    # xml_test = XmlTest(xml)

    # # xml_test.validate()
    # o = xml_test.json
    # print(type(o))
    # print(o)
    # create_post_request(o, ofile)
    # # # print(type(o))
    # # # print(json.dumps(o,indent=4))
