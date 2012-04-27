#!/usr/bin/perl

# Given a log file with "system time, buffer time in sec" records
# compares it with record in ground truth

use strict;
use warnings;
use VideoTagLogFile;
use GroundTruth;

my $logFile = $ARGV[0];
my $tagFile = $ARGV[1];

checkFile($logFile);
checkFile($tagFile);

my $videoTagFile = new VideoTagLogFile($tagFile);
my $gt = new GroundTruth();

my $logFileRecords = [];
open LF, $logFile or die "unable to open $logFile";
while(<LF>) {
    chomp($_);
    my ($systime_ms, $est_buffer_time, $video_id) = split(',', $_);

    # Get record from ground truth db containing playback time, buffered bytes, url 
    my $rec = $gt->getRecord($systime_ms);

    # Get time corresponding to bytes from log file in millisec
    my $buffer_end_time = $videoTagFile->getTime($rec->{eob_bytes});
    my $buffer_time =  $buffer_end_time - $rec->{playback_time};

    # convert time to sec
    $buffer_time /= 1000;

    #printf("%d\t%.2f\t%.2f\t%.2f\t%s\n", $systime_ms, $buffer_time, $est_buffer_time, $est_buffer_time - $buffer_time,$video_id);
    printf("%d\t%.2f\t%.2f\t%.2f\n", $systime_ms, $buffer_time, $est_buffer_time, $est_buffer_time - $buffer_time);
}

close(LF);
$gt->close();

sub checkFile {
    my $file = shift;
    if (!$file || $file eq '') {
	die "unable to open $file - $!";
    }
}

