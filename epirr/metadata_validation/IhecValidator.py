import lxml.etree


class IhecValidator():
    pass

def validate_sra(etree: lxml.etree, path_to_sra_xsd):
    try:
        schemaDoc = etree.parse(path_to_sra_xsd)
    except IOError:
        print(f"File '{path_to_sra_xsd}' not accessible")
    schema    = etree.XMLSchema(schemaDoc)
    if not schema.validate(etree):
        raise ValueError('Incopatible with SRA schema')

