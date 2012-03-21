package Net::Analysis::Listener::RequestListener;

use strict;
use base qw(Net::Analysis::Listener::HTTP);
use URI::QueryParam;
use Data::Dumper;

my $done = {};
my $req_id = 0;

my $playback_req = [];
my $s_req = [];
my @sorted_s_req = ();

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
	    push @$playback_req, $systime_ms;
	    #my $data_length = $req_mono->length();
	    #my $packet = $req_mono->first_packet();
	    #my $systime_ms = ( ($packet->[7]) + ($packet->[8]/1000000) ) * 1000;
	    #if( !exists $done->{$systime_ms} ) {
	    #    print $req_id, ',', $systime_ms, "\n";
	    #    $done->{$systime_ms} = 1;
	    #    $req_id++;
	    #}
	}
	elsif( $req =~ /\/s\?/ ) { # && $playback_req) {
	    #my $buffer_count = $uri->query_param("bc");

	    push @$s_req, {
		time => $systime_ms || '', 
		bc => $uri->query_param("bc") || '',
		rt => $uri->query_param("rt") || '',
		bd => $uri->query_param("bd") || '',
		bt => $uri->query_param("bt") || '',
		et => $uri->query_param("et") || '',
		st => $uri->query_param("st") || '',
		
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
	$done->{$systime_ms} = 1;
    }
}

END {
    my @sorted_playback_req = sort {$a <=> $b} @$playback_req;
    @sorted_s_req = sort { $a->{time} <=> $b->{time} } @$s_req;

    foreach my $playback_req_time (@sorted_playback_req) {
	my $s_data = find_closest_s_request($playback_req_time);
	#print_hash($s_data);
	print "At playback time = $playback_req_time\n";
	print Dumper $s_data;
    }
}

sub print_hash {
    my $hash = shift;
    foreach(keys %$hash) {
    }
}

sub find_closest_s_request {
    my $p_req = shift;
    foreach(@sorted_s_req) {
	if( $p_req < $_->{time} && $_->{bc} && $_->{bc} ne '' ) {
	    return $_;
	}
    }
}

1;
