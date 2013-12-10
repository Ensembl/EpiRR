package EpiRR::Config;

use Bread::Board;

sub get_container {
  return $EpiRR::Config::container;
}


our $container = container 'EpiRR' => as {
    service 'metaDataBuilder' => (
        class    => 'EpiRR::Service::CommonMetaDataBuilder',
        lifecyle => 'Singleton',
    );

    service 'conversionService' => (
        class        => 'EpiRR::Service::ConversionService',
        lifecyle     => 'Singleton',
        dependencies => {
            meta_data_builder  => depends_on('metaDataBuilder'),
            dataset_classifier => depends_on('datasetClassifier'),
            schema             => depends_on('Database/dbic_schema'),
            ena_accessor       => depends_on('enaWebAccessor'),
        },
        block => sub {
            my ($s) = @_;
            my $c = EpiRR::Service::ConversionService->new(
                meta_data_builder  => $s->param('meta_data_builder'),
                dataset_classifier => $s->param('dataset_classifier'),
                schema             => $s->param('schema'),
                archive_services   => {
                    ENA  => $s->param('ena_accessor'),
                    SRA  => $s->param('ena_accessor'),
                    DDBJ => $s->param('ena_accessor'),
                }
            );
            $c;
        }
    );

    service 'datasetClassifier' => (
        class     => 'EpiRR::Service::IhecBinaryDatasetClassifier',
        lifecycle => 'Singleton',
    );

    service 'enaWebAccessor' => (
        class        => 'EpiRR::Service::ENAWeb',
        lifecycle    => 'Singleton',
        dependencies => {
            xml_parser => depends_on('sraXmlParser'),
        }
    );

    service 'sraXmlParser' => (
        class     => 'EpiRR::Parser::SRAXMLParser',
        lifecycle => 'Singleton',
    );

    service 'textFileParser' => ( class => 'EpiRR::Parser::TextFileParser', );

    container 'Database' => as {
        service 'dsn'      => "dbi:SQLite:dbname=my-app.db";
        service 'username' => "";
        service 'password' => "";

        service 'dbic_schema' => (
            class     => 'EpiRR::Schema',
            lifecycle => 'Singleton',
            block     => sub {
                my $s = shift;
                EpiRR::Schema->connect( $s->param('dsn'),
                    $s->param('username'), $s->param('password'), )
                  || die "Could not connect";
            },
            dependencies => wire_names(qw[dsn username password])
        );
    };

};

no Bread::Board;

1;
