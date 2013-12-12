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

    service 'conversion_service' => (
        class        => 'EpiRR::Service::ConversionService',
        dependencies => {
            meta_data_builder      => depends_on('meta_data_builder'),
            dataset_classifier     => depends_on('dataset_classifier'),
            schema                 => depends_on('database/dbic_schema'),
            ena_accessor           => depends_on('ena_web_accessor'),
            array_express_accessor => depends_on('array_express_accessor'),
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
                    AE   => $s->param('array_express_accessor'),
                }
            );
            return $c;
        }
    );

    service 'dataset_classifier' => (
        class     => 'EpiRR::Service::IhecBinaryDatasetClassifier',
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

    service 'text_file_parser' => ( class => 'EpiRR::Parser::TextFileParser' );

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
