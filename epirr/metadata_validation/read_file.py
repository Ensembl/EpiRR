import sys, json
from pprint import pprint
import lxml.etree
from urllib.request import urlopen
import argparse

from Xml import Xml
from Experiment import Experiment
from Sample import Sample

def get_options():
    my_parser = argparse.ArgumentParser(
        prog='read_file',
        usage='(prog) -i <inputfile> -t <experiment or sample> [-o <outputfile>]',
        description='Example for validator')
    
    my_parser.add_argument(
        '--inputfile',
        '-i',
        metavar='path',
        type=str,
        required=True,
        help='Path to XML inputfile')

    my_parser.add_argument(
        '--type',\
        '-t',
        type=str,
        choices=['experiment', 'sample'],
        required=True,
        help='Type of XML')

    my_parser.add_argument(
        '--outputfile',
        '-o',
        metavar='path',
        type=str,
        help='Output file')
    
    my_parser.add_argument(
        '--config',
        '-c',
        metavar='path',
        type=str,
        default='config.json',
        help='Config file')

    return my_parser.parse_args()

def read_file(file):
    with open(file, 'r') as f:
        return f.read()

def read_json_file(file: str) ->dict:
    try:
        with open(file) as json_file:
            return json.load(json_file)
    except Exception as e:
        raise ValueError(f"Issues with JSON file:'{file}': {e}")

if __name__ == "__main__":

    args = get_options()
    config = read_json_file(args.config)
    xsd =  config['sra'][args.type]
    xml = read_file(args.inputfile)
    object = None
    validator_input = {}
    
    if args.type == "experiment":
        try:
            object = Experiment(xml, xsd)
        except Exception as e:
            raise (f"Error creating Experiment object: '{e}'")
    elif args.type == "sample":
        try:
            object = Sample(xml, xsd)
        except Exception as e:
            raise (f"Error creating Sample object: '{e}'")
    else:
        raise ValueError(f"Type must be experiment or sample")

    for version in config['json'][args.type] :
        validator_input['schema'] = read_json_file(config['json'][args.type][version][object.library_strategy])
        validator_input['object'] = object.json
        print(f">>>>>>>>>>> Version: {version} <<<<<<<<<<<<<<<")
        print(json.dumps(validator_input,indent=4))



############ Graveyard    


    # xsd = urlopen("https://raw.githubusercontent.com/IHEC/ihec-ecosystems/master/schemas/xml/SRA.sample.xsd").read()
    # schema = lxml.etree.XMLSchema(lxml.etree.fromstring(xsd))

    # xml = read_file(ifile)
    # try:
    #     x = Sample(xml, sra_schema)
    # except Exception as e:
    #     traceback.print_exc()

    #     print(f"Eror: '{e}'")
    #     sys.exit(1)


    # print(json.dumps(x.json,indent=4))
    # xml_test = XmlTest(xml)

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

