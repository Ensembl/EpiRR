
class IhecValidator():
    pass

def validate_sra(etree, type):
    sra_xsd = {}
    sra_xsd['experiment'] = "schemas/xml/SRA.experiment.xsd"
    sra_xsd['sample'] = "schemas/xml/SRA.sample.xsd"

    schemaDoc = etree.parse(sra_xsd[type])
    schema    = etree.XMLSchema(schemaDoc)
    if not schema.validate(etree):
        raise ValueError('Incopatible with SRA schema')

def validate_library_strategy(etree):