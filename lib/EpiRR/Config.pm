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
package EpiRR::Config;

use Bread::Board;

sub c {
    return $EpiRR::Config::container;
}

our $container = container 'EpiRR' => as {

    service 'controller' => (
        class        => 'EpiRR::App::Controller',
        dependencies => {
            conversion_service => depends_on('conversion_service'),
            schema             => depends_on( 'database/dbic_schema', )
        }
    );

    service 'conversion_service' => (
        class        => 'EpiRR::Service::ConversionService',
        dependencies => {
            meta_data_builder      => depends_on('meta_data_builder'),
            dataset_classifier     => depends_on('dataset_classifier'),
            eutils                 => depends_on('ncbi_eutils'),
            schema                 => depends_on('database/dbic_schema'),
            ena_accessor           => depends_on('ena_web_accessor'),
            array_express_accessor => depends_on('array_express_accessor'),
            geo_accessor           => depends_on('geo_accessor'),
            sra_accessor           => depends_on('sra_accessor'),
            output_service         => depends_on('output_service'),
        },
        block => sub {
            my ($s) = @_;
            my $c = EpiRR::Service::ConversionService->new(
                meta_data_builder  => $s->param('meta_data_builder'),
                dataset_classifier => $s->param('dataset_classifier'),
                schema             => $s->param('schema'),
                eutils             => $s->param('eutils'),
                output_service     => $s->param('output_service'),
                archive_services   => {
                    ENA  => $s->param('ena_accessor'),
                    SRA  => $s->param('sra_accessor'),
                    DDBJ => $s->param('ena_accessor'),
                    AE   => $s->param('array_express_accessor'),
                    GEO  => $s->param('geo_accessor'),
                }
            );
            return $c;
        }
    );

    service 'dataset_classifier' => (
        class     => 'EpiRR::Service::IhecDatasetClassifier',
        lifecycle => 'Singleton',
    );

    service 'meta_data_builder' => (
        class    => 'EpiRR::Service::CommonMetaDataBuilder',
        lifecyle => 'Singleton',
    );

    service 'ena_web_accessor' => (
        class        => 'EpiRR::Service::ENAWeb',
        lifecycle    => 'Singleton',
        dependencies => { xml_parser => depends_on('sra_xml_parser'), }
    );

    service 'array_express_accessor' => (
        class     => 'EpiRR::Service::ArrayExpress',
        lifecycle => 'Singleton',
    );

    service 'sra_xml_parser' => (
        class     => 'EpiRR::Parser::SRAXMLParser',
        lifecycle => 'Singleton',
    );

    service 'geo_accessor' => (
        class     => 'EpiRR::Service::GeoWeb',
        lifecycle => 'Singleton',
    );

    service 'sra_accessor' => (
        class        => 'EpiRR::Service::SRAEUtils',
        lifecycle    => 'Singleton',
        dependencies => {
            sra_xml_parser => depends_on('sra_xml_parser'),
            eutils         => depends_on('ncbi_eutils'),
        }
    );

    service 'json_file_parser' => ( class => 'EpiRR::Parser::JsonParser' );

    service 'contact_email' => 'VALID_EMAIL';

    service 'ncbi_eutils' => (
        class        => 'EpiRR::Service::NcbiEUtils',
        lifecycle    => 'Singleton',
        dependencies => { email => depends_on('contact_email'), }

    );

    service 'text_file_parser' => ( class => 'EpiRR::Parser::TextFileParser' );

    service 'output_service' => (
        class        => 'EpiRR::Service::OutputService',
        lifecycle    => 'Singleton',
        dependencies => { schema => depends_on( 'database/dbic_schema', ) }
    );

    service 'accession_service' => (
        class        => 'EpiRR::Service::AccessionService',
        lifecycle    => 'Singleton',
        dependencies => {
            output_service     => depends_on('output_service'),
            conversion_service => depends_on('conversion_service'),
            text_parser        => depends_on('text_file_parser'),
            json_parser        => depends_on('json_file_parser'),
        }
    );

    container 'database' => as {
        service 'dsn'      => "dbi:SQLite:dbname=epirr.db";
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
