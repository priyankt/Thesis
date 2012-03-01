#!/usr/bin/perl

use strict;
use warnings;
use Chart::Gnuplot;

my $file = $ARGV[0];
my $prefix = $ARGV[1] || '';

my $xdata = [];
my $ydata_time = [];
my $ydata_bytes = [];

open FH, $file or die "Cannot open file for reading - $file\n";
while(<FH>) {
    my ($t, $b, $T, $B) = split(',', $_);
    push @$xdata, $t/1000;
    print STDERR $t/1000, ", ";
    push @$ydata_time, ($T-$t)/1000;
    print STDERR ($T-$t)/1000, ", ";
    push @$ydata_bytes, ($B-$b)/1000;
    print STDERR ($B-$b)/1000, "\n";
}
close(FH);

my $dataset_time = Chart::Gnuplot::DataSet->new(
    xdata => $xdata,
    ydata => $ydata_time,
    title => 'detla(time)',
    style => 'lines',
);

my $dataset_bytes = Chart::Gnuplot::DataSet->new(
    xdata => $xdata,
    ydata => $ydata_bytes,
    title => 'detla(bytes)',
    style => 'lines',
);

my $time_chart = Chart::Gnuplot->new(
        output => "charts/".$prefix."_buffered_time.png",
        title  => "player buffer status",
        xlabel => "playback time in sec",
        ylabel => "buffered time in sec",
);

$time_chart->plot2d($dataset_time);

my $bytes_chart = Chart::Gnuplot->new(
        output => "charts/".$prefix."_buffered_bytes.png",
        title  => "Player buffer status",
        xlabel => "playback time in sec",
        ylabel => "buffered bytes in kB",
);

$bytes_chart->plot2d($dataset_bytes);
