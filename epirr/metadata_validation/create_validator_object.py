import sys, lxml.etree, json, urllib.request, urllib.error
from pprint import pprint

def parse_xml(file):
    try:
        return lxml.etree.parse(file)
    except lxml.etree.ParseError:
        raise ValueError(f"Invalid XML{file}")
    except IOError:
        raise IOError(f"Could not open file {file}")

def fetch_ihec_schema(url):
    request = urllib.request.Request(url)
    try: 
        with urllib.request.urlopen(request) as url:
            return json.loads(url.read().decode())
    except urllib.error.HTTPError as e:
        print (f'Could not get schema {url}: Error code:{e.code}')
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f'Reason:{e.reason}')
        sys.exit(1)

def create_validator_schema(ihec_schema):
    return {**ihec_schema['properties'], **ihec_schema['definitions']['chromatin_accessibility']['properties']}

def create_experiment_attribute_tag_list(validator_schema):
    tags = list(validator_schema.keys())
    tags.remove('library_strategy')
    return tags

def create_validator_object(etree, experiemt_attribute_tags):
    object = {}
    for tag in experiemt_attribute_tags:
        xpath = f".//EXPERIMENT_ATTRIBUTE[TAG='{tag.upper()}']/VALUE"
        if etree.xpath(xpath):
            object[tag.lower()] = etree.xpath(xpath)[0].text.lower()
    return object

def create_validator_input(schema, object):
    return {"schema": schema, "object":object}


if __name__ == "__main__":
    url_ihec_schema = "https://raw.githubusercontent.com/IHEC/ihec-ecosystems/master/schemas/json/2.0/experiment.json"
    file_input_xml   = "/Users/juettema/repos/EpiRR/epirr/metadata_validation/files/exp_chromantin.xml"
    etree    = parse_xml(file_input_xml)
    ihec_schema  = fetch_ihec_schema(url_ihec_schema)
    validator_schema = create_validator_schema(ihec_schema)
    experiemt_attribute_tags = create_experiment_attribute_tag_list(validator_schema)
    validator_object = create_validator_object(etree, experiemt_attribute_tags)
    validator_input = create_validator_input(validator_schema, validator_object)
    with open ('new.json', 'w') as f:
        f.write(json.dumps(validator_input,indent=4))

