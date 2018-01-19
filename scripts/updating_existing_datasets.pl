
#all the imports needed
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
use EpiRR::Service::ENAInternal;
#



#Changed the config_module EpiRR::Config to EpiRR::Config::New_EpiRR_Schema#
my $config_module = 'EpiRR::Config::New_EpiRR_Schema';
#

#Lines of code like in batch_accession.pl
eval("require $config_module")
  or croak "cannot load module $config_module $@";
my $container = $config_module->c();
my $database_service = $container->resolve( service => 'database/dbic_schema' );
my $conversion_service = $container->resolve( service => 'conversion_service' );
my @all_raw_data = $database_service->raw_data->all;



#Getting all datasets for which the archive is EGA

foreach my $raw_data(@all_raw_data){
        if ($raw_data->archive->name eq'EGA') {
		if ($raw_data->dataset_version->is_current ){
                	my $errors = [];
                	print $raw_data->primary_accession, "\n";
			print $raw_data->dataset_version->is_current, "\n";
			my @list_of_EGAX = ($raw_data->primary_accession,); 
			foreach my $n (@list_of_EGAX){
				#say $n;
				my $accessor = $conversion_service->get_accessor($raw_data->archive->name);

				my $experiment = $accessor->experiment_xml($n , $errors);
		        	print Dumper($experiment->meta_data);	
                        
				my @original_meta_data = qw( primary_id secondary_id archive archive_url experiment_type assay_type );  
                        	my %orig_meta_data     = map {$_ => 1} @original_meta_data;
    		        	while ( my ( $k, $v ) = each %{$experiment->meta_data}) {
                         
 					if ( ! exists $orig_meta_data{$k} ) {
         			       	$raw_data->add_to_raw_meta_datas(
             			       
             			        	{
                 				name  => $k,
                 				value => $v
 			 		 	});
 			
 					#print ("k: ");
                         		#print $k."\n";
                         		#print("v: ");
                         		#print $v."\n";
 		 		}
 			}		
		

	}	
	
}			
			
		
		#my $experiment= $self->experiment_xml( $raw_data->primary_id(), $errors );		
#my $exp_xml = experiment_xml 
                }
	}	




exit;
#Lines of code like in the config files EpiRR-Config/Config 
my $database_ega = $container->resolve( service => 'ega_internal_accessor' );


#print Dumper($database_ega);


#Database independent interface for Perl 
my $dbh = $database_ega->{database_handle};
my $sth = $dbh->prepare("select xmltype.getclobval(experiment_xml) from experiment where ega_id='EGAX00001272833'");
$sth->execute;
my $hash_ref = $sth->fetchrow_hashref;
print Dumper(values %$hash_ref);




