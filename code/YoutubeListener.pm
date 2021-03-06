package Net::Analysis::Listener::YoutubeListener;

use strict;
use base qw(Net::Analysis::Listener::HTTP);
use URI::QueryParam;
use Data::Dumper;
use PacketData;
use DateTime;

use constant VIDEO_BASE_DIR => '/home/priyank/Thesis/code/flv/';
use constant LOG_BASE_DIR => '/home/priyank/Thesis/code/log/';


my $options = {
    generate_log_file => 1,
    save_flv_file => 0,
};

my $total_data = 0;
my $done = {};
my $data = {};

my @sorted = ();
my $id = 0;

sub http_transaction {

    my ($self, $args) = @_;

    my ($http_req) = $args->{req};
    my ($http_resp) = $args->{resp};
    my ($resp_mono) = $args->{resp_mono};

    if(!$http_req) {
	print STDERR "Undefined request header found\n";
	return;
    }

    my $uri = $http_req->uri();

    # Extract content-length & content-type from response headers
    my $content_length = $http_resp->header('content-length');
    my $content_type = $http_resp->header('content-type');

    # Check if content_type is video/x-flv
    if ($content_type =~ /video\/x-flv/i && $content_length != 0) {

        # Extract range or begin parameter present in request url
	my $range = $uri->query_param('range');
	my $begin = $uri->query_param('begin');
	my $suffix = '';
	if($range) {
	    my ($start_byte, $end_byte) = split('-', $range);
	    $suffix .= $start_byte . '_' . $end_byte;
	}
	elsif($begin && $begin ne '') {
	    $suffix .= $begin;
	}
	else {
	    # When begin and no forward, then video has only one request and no begin time
	    $suffix .= '0'; # IMP - define suffix
	    $begin = 'start'; # IMP - define begin with some value, 0 works as false :-(
	}

	# get time when request was sent
	my $req_time = get_request_time( $args->{req_mono} );

        # Save the contents for future reference
	if(!$done->{$req_time}) {

	    ############ Qucik Fix for same video downloaded multiple times ###############
	    if($suffix eq '0') {
		$suffix .= "_$id";
		$id++;
	    }
	    ####################################################
	    my $fname = VIDEO_BASE_DIR . $uri->query_param('id') . '_' . $suffix . '.flv';

	    print STDERR "Dumping ".length($http_resp->content)." bytes to ".$fname." be patient...\n";
	    if( $options->{save_flv_file} ) {
		open(FH, '>', $fname) or die "unable to open file for writing - $fname\n";
		print FH $http_resp->content;
		close(FH);
	    }

	    # $data_length is including response header
	    my $data_length = $resp_mono->length();

	    # Calculate response header size that needs to be skipped

            # Get all packets that contribute for response
	    my $packets = $resp_mono->which_pkts(0, [$data_length]);

	    my $header_found = 0;
            # Iterate over each received TCP packet
	    foreach my $packet (@$packets) {
		my $flv_content = '';
		if(!$header_found) { # if header is still in packet data
		    # check if header ends in this packet by comparing with '\r\n\r\n'
		    if ( $packet->[3] =~ /\r\n\r\n(.*)/ ) {
			if($1) {
			    $flv_content = $1;
			}
			$header_found = 1;
		    }
		    else { # if header not found in this packet
			next;
		    }
		}
		else {
		    $flv_content = $packet->[3];
		}

		my $systime_ms = ( ($packet->[7]) + ($packet->[8]/1000000) ) * 1000;
		if($flv_content && $flv_content ne '') {
		    if($range) {
			push @{ $data->{$uri->query_param('id')}{range}{$suffix} }, { time => $systime_ms, key=>$suffix, content=>$flv_content, id=>$uri->query_param('id')};
		    }
		    if($begin) {
			push @{ $data->{$uri->query_param('id')}{begin}{$suffix} }, { time => $systime_ms, key=>$suffix, content=>$flv_content, id=>$uri->query_param('id')};
		    }
		}
	    }
	    $done->{$req_time} = 1;
	}
    }
}

END {

    # Put all the files in todays date folder
    my $dt = DateTime->today->ymd;
    my $LOG_DIR = LOG_BASE_DIR . "$dt/";
    if(! -d $LOG_DIR) {
	mkdir $LOG_DIR or die "Unable to create directory $LOG_DIR";
    }

    # Do for each youtibe id video found in pcap file
    foreach my $youtube_id (keys %$data) {
        # loop on both begin and range request types
	foreach my $req_type (keys %{$data->{$youtube_id}}) {
	    # so if 12345-26272 and 26273-35647 are two ranges then mearge into 12345-35647 for later processing
	    if($req_type eq 'range') {
		my $packet_data = merge_ranges($data->{$youtube_id}{$req_type});
		if($options->{generate_log_file}) {
		    $options->{log_filename} = $LOG_DIR . "$youtube_id".'.log';
		    print $options->{log_filename}, "\n";
		}
		foreach (keys %$packet_data) {
		    my $pd = new PacketData($packet_data->{$_}, $options);
		    eval {
			$pd->process_data($req_type);
		    };
		    if($@) {
			if($@ =~ /^Max\spacket\snumber\sreached/) {
				print STDERR "Max packet number reached. Going for next request..\n";
			}    
		    }
		}
	    }
	    else {
		foreach my $start_time (keys %{$data->{$youtube_id}{$req_type}}) {
		    if($options->{generate_log_file}) {
			$options->{log_filename} = $LOG_DIR . "$youtube_id".'.log';
			print $options->{log_filename}, "\n";
		    }
		    my $pd = new PacketData($data->{$youtube_id}{$req_type}{$start_time}, $options);
		    eval {
			$pd->process_data($req_type); # process each begin request
		    };
		    if($@) {
			if($@ =~ /^Max\spacket\snumber\sreached/) {
			    print STDERR "Max packet number reached. Going for next request..\n";
			}
		    }
		}
	    }
	}
    }
}


sub get_request_time {
    my $req_mono = shift;
    my $packet = $req_mono->first_packet();
    my $systime_ms = ( ($packet->[7]) + ($packet->[8]/1000000) ) * 1000;
    return $systime_ms;
}

sub merge_ranges {
    my $ranges = shift;

    # sort by start of range
    my $merged = [];
    foreach my $range (sort keys %$ranges) {
	my ($begin, $end) = split('_', $range);
	push @$merged, {begin=>$begin, end=>$end, range=>$range};
    }

    my @sorted = sort { $a->{begin} <=> $b->{begin} } @$merged;

    my $new_range = {};
    my $prev = 0;
    my @temp = ();
    for(my $i=0; $i < scalar(@sorted); $i++) {
	if( $i+1 < scalar(@sorted) ) {
	    if( $sorted[$i]->{end}+1 != $sorted[$i+1]->{begin} ) {
		#print STDERR $sorted[$prev]->{begin}, '-', $sorted[$i]->{end}, "\n";
		push @temp, @{$ranges->{$sorted[$i]->{range}}};
		$new_range->{$sorted[$prev]->{begin}.'_'.$sorted[$i]->{end}} = \@temp;
		$prev = $i+1;
		undef(@temp);
	    }
	    else {
		push @temp, @{$ranges->{$sorted[$i]->{range}}};
	    }
	}
	else {
	    push @temp, @{$ranges->{$sorted[$i]->{range}}};
	    $new_range->{$sorted[$prev]->{begin}.'_'.$sorted[$i]->{end}} = \@temp;
	    #print STDERR $sorted[$prev]->{begin}, '-', $sorted[$i]->{end}, "\n";
	}
    }
    return $new_range;
}

1;
