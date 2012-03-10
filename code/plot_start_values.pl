#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use StartTimeExperiment;

my $player_file = 'json.txt';
my $nw_file = '';
my $outfile = 'initial_bytes_time.jpg';
my $format = 'json';
my $debug = 0;
my $graph = 1;

GetOptions(
    "player-file=s" => \$player_file,
    "network-file=s" => \$nw_file,
    "outfile=s" => \$outfile,
    "format=s" => \$format,
    "debug" => \$debug,
    "graph" => \$graph,
    );

my $experiment = StartTimeExperiment->new({
    player_file => $player_file,
    format => $format,
    xstart => 0,
});

while(1) {
	eval {
		my $load_time = $experiment->load_time();
		my $start_time = $experiment->start_time();
		my $time_to_start = $start_time - $load_time;
		my $buffered_kb = $experiment->buffered_bytes({kilobytes => 1});
		if($graph) {
			$experiment->add_to_graph($time_to_start, $buffered_kb);
		}
		if($debug) {
			print STDERR $start_time - $load_time, ', ', $buffered_kb, "\n";
		}
$experiment->next();
	};
	if($@) {
		if($@ =~ /^END:/) {
			last;
		}
		elsif($@ =~ /^NO START:/) {
			next;
		}
		else {
			die $@;
		}
	}
}

if($graph) {
$experiment->plot_graph($outfile);
}
