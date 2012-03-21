package Net::Analysis::Listener::StatusRequestListener;

use strict;
use base qw(Net::Analysis::Listener::HTTP);
use URI::QueryParam;
use Data::Dumper;

my $done = {};

my $s_req = [];

sub http_transaction {

    my ($self, $args) = @_;

    my ($http_req) = $args->{req};
    my ($http_resp) = $args->{resp};
    my ($req_mono) = $args->{req_mono};

    if(!$http_req) {
	print STDERR "Undefined request header found\n";
	return;
    }

    my $uri = $http_req->uri();
    my $req = $uri->as_string;

    my $packet = $req_mono->first_packet();
    my $systime_ms = ( ($packet->[7]) + ($packet->[8]/1000000) ) * 1000;

    if(!exists $done->{$systime_ms}) {
	if($req =~ /\/videoplayback\?/ && $http_resp->{_rc} == 200) {
	    # sort and print s_req for previos video playback
	    if(scalar(@$s_req)) {
		my @sorted = sort { $a->{et} <=> $b->{et} } @$s_req;
		print Dumper \@sorted;
		$s_req = [];
	    }

	    # Print new video playback request
	    print "===================== videoplayback = ".$systime_ms, " =======================\n";
	}
	elsif( $req =~ /\/s\?/ ) { # && $playback_req) {

	    my $bc = $uri->query_param("bc");
	    if($bc) {
		push @$s_req, {
		    time => $systime_ms || '',
		    docid => $uri->query_param("docid"),
		    bc => $bc || '',
		    rt => $uri->query_param("rt") || '',
		    bd => $uri->query_param("bd") || '',
		    bt => $uri->query_param("bt") || '',
		    et => $uri->query_param("et") || '',
		    st => $uri->query_param("st") || '',
		    len => $uri->query_param("len") || '',
		
		    hbd => $uri->query_param("hbd") || '',
		    hcbd => $uri->query_param("hcbd") || '',
		    hcbt => $uri->query_param("hcbt") || '',
		    hbt => $uri->query_param("hbt") || '',
		    pd => $uri->query_param("pd") || '',
		
		    nsivbblc => $uri->query_param("nsivbblc") || '',
		    nsiabblc => $uri->query_param("nsiabblc") || '',
		    nsivbblmin => $uri->query_param("nsivbblmin") || '',
		    nsivbblmean => $uri->query_param("nsivbblmean") || '',
		    nsivbblmax => $uri->query_param("nsivbblmax") || '',
		    nsiabblmin => $uri->query_param("nsiabblmin") || '',
		    nsiabblmean => $uri->query_param("nsiabblmean") || '',
		    nsiabblmax => $uri->query_param("nsiabblmax") || '',
		};
	    }
	}
	$done->{$systime_ms} = 1;
    }
}

1;
