#!/usr/bin/perl

use strict;
use warnings;
use JSON;
use Chart::Gnuplot;
use Data::Dumper;

my $json_file = $ARGV[0] || 'json.txt';
my $nw_file = $ARGV[1];
my $outfile = $ARGV[2] || 'initial_bytes_time.jpg';

open JFH, $json_file or die "Unable to open file $json_file";
my $json_str = <JFH>;
close(JFH);

my $nw_data = {};
if($nw_file ne '') { 
    open NFH, $nw_file or die "Unable to open file $nw_file";
    while(<NFH>) {
	my ($index, $time) = split(',', $_);
	$nw_data->{$index} = $time;
    }
    close(NFH);
}

my $json = JSON->new->allow_nonref;
my $data = $json->decode($json_str);

my $video_index = 0;
my $xdata = [];
my $ydata = [];

while( $video_index < scalar(@$data) ) {
    # if nw file is not provided then calculate from json file
    if($nw_file eq '') {
	if($data->[$video_index+2]->{event_type} eq 'start' && $data->[$video_index]->{event_type} eq 'load') {
	    push @$xdata, ( $data->[$video_index+2]->{system_time} - $data->[$video_index]->{system_time} ); # - $data->[$video_index+2]->{playback_time});
	    print $data->[$video_index+2]->{system_time} - $data->[$video_index]->{system_time}, ' , ', $data->[$video_index+2]->{playback_time};
	}
	else {
	    die "Not load and start pattern at $video_index";
	}
    }
    else {
	push @$xdata, ( $data->[$video_index+2]->{system_time} - $nw_data->{$video_index/3} );
    }
    # insert bytes loaded at start in KB
    #push @$ydata, ( $data->[$video_index+2]->{eob_bytes} - $data->[$video_index]->{eob_bytes} )/$data->[$video_index+2]->{bytes_total};
    push @$ydata, ( $data->[$video_index+2]->{eob_bytes} - $data->[$video_index]->{eob_bytes} ) / 1024;
    print ' , ', ( $data->[$video_index+2]->{eob_bytes} - $data->[$video_index]->{eob_bytes} ) / 1024, "\n";
    $video_index += 3;
}

my $dataset = Chart::Gnuplot::DataSet->new(
    xdata => $xdata,
    ydata => $ydata,
    style => 'points',
);

my $chart = Chart::Gnuplot->new(
        output => "charts/$outfile",
        title  => "Player start buffer status",
        xlabel => "time (millisec)",
        ylabel => "buffered bytes (KB)",
);

$chart->plot2d($dataset);


