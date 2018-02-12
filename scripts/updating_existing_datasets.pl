
use warnings;
use strict;
use EpiRR::Schema;
use Getopt::Long;
use Carp;
use File::Find;
use File::Spec;
use File::Basename;
use autodie;
use feature qw(say);
use Data::Dumper;
use utf8;

my $config_module = 'EpiRR::Config';

GetOptions(
  "config=s" => \$config_module,
) 
  or croak("Error with options: $!");
eval("require $config_module")
  or croak "cannot load module $config_module $@";

my $container = $config_module->c();
my $database_service = $container->resolve( service => 'database/dbic_schema' );
my $conversion_service = $container->resolve( service => 'conversion_service' );
my @all_raw_data = $database_service->raw_data->all;

foreach my $raw_data(@all_raw_data){
        if ($raw_data->archive->name eq'EGA') {
		if ($raw_data->dataset_version->is_current ){
                	my $errors = [];
			my @list_of_EGAX = ($raw_data->primary_accession,); 
			foreach my $n (@list_of_EGAX){

				my $accessor = $conversion_service->get_accessor($raw_data->archive->name);
				my $experiment = $accessor->experiment_xml($n , $errors);

				my $sample = $accessor->lookup_sample( $experiment->sample_id(), $errors ) if ($experiment->sample_id());

				my @original_meta_data = qw( primary_id secondary_id archive archive_url experiment_type assay_type library_strategy);  
                        	my %orig_meta_data     = map {$_ => 1} @original_meta_data;

    		        	while ( my ( $k, $v ) = each %{$experiment->meta_data}) {
 					if ( ! exists $orig_meta_data{$k} ) {
         			       		$raw_data->add_to_raw_meta_datas(
             			        	{
                 					name  => $k,
                 					value => $v
 			 		 	});
 		 			}
		        	}

				# If molecule and molecule_ontology_uri are still set within the sample XML, copy them over to the experiment 
			        if ( $sample->get_meta_data('molecule') && ! $eexperiment->get_meta_data('molecule') ) {
					$raw_data->add_to_raw_meta_datas(	
     					{
						name  => 'molecule', 
						value => $sample->get_meta_data('molecule'))
					});
				}

			        if ( $sample->get_meta_data('molecule_ontology_uri') && ! $eexperiment->get_meta_data('molecule_ontology_uri') ) {
					$raw_data->add_to_raw_meta_datas(	
     					{
						name  => 'molecule_ontology_uri', 
						value => $sample->get_meta_data('molecule_ontology_uri'))
					});
				}
			}
		}					
	}
}	


