#!/usr/bin/perl

use strict;
use warnings;
use Chart::Gnuplot;

my $id_str = $ARGV[0];

my @ids = split(',', $id_str);
my $dataset_time_arr = [];
my $dataset_bytes_arr = [];

foreach my $id (@ids) {
    my $file = 'flv/'.$id.'_mapping.log';
    open FH, $file or die "Unable to open file $id for reading\n";
    my $xdata = [];
    my $ydata_time = [];
    my $ydata_bytes = [];

    print STDERR "Reading file $file\n";
    while(<FH>) {
	my ($t, $b, $T, $B) = split(',', $_);
	push @$xdata, $t/1000;
	#print STDERR $t/1000, ", ";
	push @$ydata_time, ($T-$t)/1000;
	#print STDERR ($T-$t)/1000, ", ";
	push @$ydata_bytes, ($B-$b)/1024; # 1 KB = 1024 bytes
	#print STDERR ($B-$b)/1000, "\n";
    }
    print STDERR "Finished reading file $file\n";

    my $dataset_time = Chart::Gnuplot::DataSet->new(
	xdata => $xdata,
	ydata => $ydata_time,
	title => $id,
	style => 'lines',
	);
    push @$dataset_time_arr, $dataset_time;

    my $dataset_bytes = Chart::Gnuplot::DataSet->new(
	xdata => $xdata,
	ydata => $ydata_bytes,
	title => $id,
	style => 'lines',
	);
    push @$dataset_bytes_arr, $dataset_bytes;
    
    close(FH);
}

my @knee_points_data = (
    [2.717, 37.443],
    [4.296, 44.905],
    [13.189, 51.206],
    [2.206, 31.905],
);

my $knee_points_dataset = Chart::Gnuplot::DataSet->new(
    points => \@knee_points_data,
    title => 'knee point',
    style => 'points',
    color => 'black',
    pointtype => 'fill-circle',
	);

push @$dataset_time_arr, $knee_points_dataset;

my @end_points = (
    [169.970, 79.710],
    [182.927, 82.313],
    [177.191, 80.249],
    [184.227, 82.915],
    );

my $end_point_dataset = Chart::Gnuplot::DataSet->new(
    points => \@end_points,
    title => 'end points',
    style => 'points',
    color => 'black',
    pointtype => 'fill-triangle',
	);
push @$dataset_time_arr, $end_point_dataset;

my $time_chart = Chart::Gnuplot->new(
        output => "charts/knee_buffered_time_interpolated.jpg",
        title  => "Player buffered time status",
        xlabel => "playback time(sec)",
        ylabel => "buffered time(sec)",
);

$time_chart->plot2d(@$dataset_time_arr);

my $bytes_chart = Chart::Gnuplot->new(
        output => "charts/knee_buffered_bytes.png",
        title  => "Player buffered bytes status",
        xlabel => "playback time(sec)",
        ylabel => "buffered bytes(KB)",
);

$bytes_chart->plot2d(@$dataset_bytes_arr);

