#!/usr/bin/perl

use strict;
use warnings;

# get player log file
my $player_file = $ARGV[0];

# get network dump file
my $nw_file = $ARGV[1];

#my $bytes_index = 0;
#my $time_index = 0;

my $nw_data = [];

process();

sub process {
    open NFH, $nw_file or die "Cannot open $nw_file for reading";
    while(<NFH>) {
	my ($sys_time, $type, $playback_time, $tag_size, $total_bytes, $prefix, $id) = split(',', $_);
	push @$nw_data, [$playback_time, $total_bytes];
    }
    close(NFH);
    
    open PFH, $player_file or die "Cannot open $player_file for reading";
# ignore header info in file
    my $header = <PFH>;
    while(<PFH>) {
	my ($sys_time, $playback_time, $buff_bytes, $status, $quality, $file_size_bytes, $total_duration, $video_start_bytes) = split(',', $_);
	my $playback_bytes = get_playback_bytes($nw_data, $playback_time);
	my $buff_time = get_buffered_time($nw_data, $buff_bytes);

	if($playback_bytes != -1 && $buff_time != -1) {
	    print int($playback_time), ", $playback_bytes, $buff_time, $buff_bytes\n";
	}
	else {
	    print STDERR "No more network dump file records\n";
	    last;
	}
    }
    close(PFH);
}


sub get_playback_bytes {
    my ($nw_data, $playback_time) = @_;

    my $bytes_index = 0;
    my $retval = 0;
    while( $bytes_index < scalar(@$nw_data) && $playback_time >= $nw_data->[$bytes_index]->[0] ) {
	$bytes_index++;
    }

    if( $bytes_index > 0 && $bytes_index < scalar(@$nw_data) ) {
	$retval = $nw_data->[$bytes_index-1]->[1];
    }
    elsif( $bytes_index == scalar(@$nw_data) ) {
	$retval = $nw_data->[$bytes_index-1]->[1];
    }
    else {
	$retval = -1;
    }

    return $retval;
}

sub get_buffered_time {
    my ($nw_data, $buff_bytes) = @_;

    my $time_index = 0;
    my $retval = 0;
    while( $time_index < scalar(@$nw_data) && $buff_bytes >= $nw_data->[$time_index]->[1] ) {
	$time_index++;
    }

    if( $time_index > 0 && $time_index < scalar(@$nw_data) ) {
	# For simple version w/o interpolation, remove comment on below line
	#$retval = $nw_data->[$time_index-1]->[0];

	my $ct = $nw_data->[$time_index]->[0];
	my $pt = $nw_data->[$time_index-1]->[0];
	my $cb = $nw_data->[$time_index]->[1];
	my $pb = $nw_data->[$time_index-1]->[1];

	if($cb != $pb) {
	    $retval = $pt + (($ct-$pt)/($cb-$pb)) * ($buff_bytes-$pb); # interpolat buffered time
	}
	else { # if previous buffered bytes and current buffered bytes are same then take current time
	    $retval = int($ct);
	}
    }
    elsif( $time_index == scalar(@$nw_data) ) { # check last record
	$retval = $nw_data->[$time_index-1]->[0];
    }
    else {
	$retval = -1;
    }

    return $retval;
}
