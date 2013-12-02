package EpiRR::Service::ENAWeb;

use Moose;
use LWP;
use Carp;
use URI::Encode qw(uri_encode);

with 'EpiRR::Service::ArchiveAccessor';

has 'user_agent' => (
    is       => 'rw',
    isa      => 'LWP::UserAgent',
    required => 1,
    lazy => 1,
    default  => sub { LWP::UserAgent->new( agent => "EpiRR/$EpiRR::VERSION" ); }
);

sub lookup_experiment {
  my ($self,$experiment_id) = @_;

  confess("Experiment ID is required") unless $experiment_id;

  my $xml_ref = $self->get_xml($experiment_id);
  
  
  
}


sub get_xml {
  my ($self,$id) = @_;
  
  confess("ID is required") unless $id;
  
  my $encoded_id = uri_encode($id);
  
  my $url = 'http://www.ebi.ac.uk/ena/data/view/'.$encoded_id.'&display=xml';
  my $req = HTTP::Request->new(GET => $url);
  
  my $res = $ua->request($req);
  my $xml;
  # Check the outcome of the response
  if ($res->is_success) {
      $xml = $res->content;      
  }
  else {
    confess("Error requesting $url:".$res->status_line);
  }
  
  return $xml;
}

1;
