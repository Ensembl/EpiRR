# Copyright 2013 European Molecular Biology Laboratory - European Bioinformatics Institute
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
package EpiRR::IntegrationTestConfig;

use Bread::Board;

sub c {
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
        dependencies => { xml_parser => depends_on('sraXmlParser'), }
    );

    service 'sraXmlParser' => (
        class     => 'EpiRR::Parser::SRAXMLParser',
        lifecycle => 'Singleton',
    );

    service 'textFileParser' => ( class => 'EpiRR::Parser::TextFileParser', );

    container 'Database' => as {
        service 'dsn'      => "dbi:SQLite:dbname=:memory:";
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
