#!/usr/bin/perl

use strict;
use warnings;

use FLV::File;
use Data::Dumper;

# Get filename
my $flv_file = $ARGV[0];
my $header = 0 || $ARGV[1];
if(!$flv_file) {
    die "Please provide flv file on command line";
}

my $file = FLV::File->new();
my $opts = {header => $header};
$file->parse($flv_file, $opts);
my $flv_body = $file->get_body();


my $total_data = 0;
my @tags = $flv_body->get_tags();
foreach my $tag (@tags) {

    my $type;
    my $is_meta_tag = 0;
    if(!$tag->isa('FLV::MetaTag')) {
	if($tag->isa('FLV::VideoTag')) {
	    $type = 'video';
	}
	if($tag->isa('FLV::AudioTag')) {
	    $type = 'audio';
	}
    }
    else {
	$is_meta_tag = 1;
    }

    if($is_meta_tag) {
	print "meta, $tag->{start}, $tag->{datasize}\n";
    }
    else {
	my $playback_time = $tag->get_time();
	print "$type, $playback_time, $tag->{datasize}\n";
    }
    $total_data += $tag->{datasize};
}

my %info = $file->get_info();
print STDERR Dumper(\%info);
print STDERR "Total data = $total_data\n";


