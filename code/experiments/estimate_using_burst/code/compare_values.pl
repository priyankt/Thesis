#!/usr/bin/perl

use strict;
use warnings;

use constant TEMP_FILE => '/tmp/temp.log';

my $pcapFile = $ARGV[0];
my $prefix;

$pcapFile =~ /.*\/(.*)\.pcap/;
if($1) {
    $prefix = $1;
}

#my $logFile = 'log/' . $prefix . '.log';

# execute to get buffer estimates
my @log = `perl packet_capture.pl --offline --file=$pcapFile`;

# get tag timestamp log file
my @tagLogFiles = `perl -MNet::Analysis -e main HTTP YoutubeListener $pcapFile`;
chomp(@tagLogFiles);

my @lines = ();
for(my $i=0; $i < scalar(@log); $i++) {
    my $curr_id = (split(',', $log[$i]))[2];
    chomp $curr_id;

    my $next_id;
    # if last record in log file, then next_index will be undef
    if($i != $#log) {
	$next_id = (split(',', $log[$i+1]))[2];
	chomp $next_id;
    }

    # if index not same then they belong to other video
    if( $i == $#log || ($curr_id ne $next_id) ) {

	push @lines, $log[$i] if($i == $#log);
	open(FH, '>', TEMP_FILE) or die "Unable to open " . TEMP_FILE . " for writing";
	print FH join('', @lines);
	close(FH);

	# clear @lines array
	@lines = ();

	my $logFile = TEMP_FILE;
	my $tagFile = getTagFile(\@tagLogFiles, $curr_id);
	my $output = `perl compare_buffer_est.pl $logFile $tagFile`;
	print $output;
    }
    else { # if index same then push them for writing into temp file
	push @lines, $log[$i];
    }
}

sub getTagFile {
    my ($tagFiles, $video_id) = @_;
    my $file = '';
    foreach(@$tagFiles) {
	if($_ =~ /$video_id/) {
	    $file = $_;
	    last;
	}
    }
    return $file;
}
