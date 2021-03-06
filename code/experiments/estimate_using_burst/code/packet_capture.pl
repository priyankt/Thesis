#!/usr/bin/perl

use strict;
use warnings;

use Net::Pcap;
use NetPacket::Ethernet;
use NetPacket::IP;
use NetPacket::TCP;
use Time::HiRes qw/gettimeofday/;
use Getopt::Long;
use TcpFlow;
use Utils;
use Point;
use Log;

use Data::Dumper;

use constant DUMP_BASE => '../pcap/';
use constant LOG_INTERVAL => 2; # log values every 5 seconds

my $offline = 0;
my $filename = '';
my $dev;
my $snaplen = 15000;
my $dumpfile;
my $debug = 0;

GetOptions(
    "offline" => \$offline,
    "file=s" => \$filename,
    "device=s" => \$dev,
    "snaplen=s" => \$snaplen,
    "dump=s" => \$dumpfile,
    "debug" => \$debug,
    );

if($offline && ( !$filename || $filename eq '' ) ) {
    print STDERR "Please input filename for offline mode.\n";
    exit;
}

if($dumpfile) {
    $dumpfile = DUMP_BASE . $dumpfile;
}

# Declare objects
my $utils = new Utils();
my $tcpFlow = new TcpFlow();
my $log = new Log(1000); # log every 2000 millisec or 2 sec
my $err;

#   Use network device passed in program arguments or if no 
#   argument is passed, determine an appropriate network 
#   device for packet sniffing using the 
#   Net::Pcap::lookupdev method

my ($address, $netmask);
if(!$offline) {
    unless (defined $dev) {
	$dev = Net::Pcap::lookupdev(\$err);
	if (defined $err) {
	    die 'Unable to determine network device for monitoring - ', $err;
	}
    }

    #   Look up network address information about network 
    #   device using Net::Pcap::lookupnet - This also acts as a 
    #   check on bogus network device arguments that may be 
    #   passed to the program as an argument

    if (Net::Pcap::lookupnet($dev, \$address, \$netmask, \$err)) {
	die 'Unable to look up device information for ', $dev, ' - ', $err;
    }
}

#   Create packet capture object on device

my $object;

if(!$offline) {
    $object = Net::Pcap::open_live($dev, $snaplen, 0, 0, \$err);
}
else {
    $object = Net::Pcap::open_offline($filename, \$err);
}
unless (defined $object) {
    die 'Unable to create packet capture ', $err;
}

my $dumper;
if($dumpfile) {
    $dumper = Net::Pcap::pcap_dump_open($object, $dumpfile);
}

#   Compile and set packet filter for packet capture 
#   object - For the capture of TCP packets with the SYN 
#   header flag set directed at the external interface of 
#   the local host, the packet filter of '(dst IP) && (tcp
#   [13] & 2 != 0)' is used where IP is the IP address of 
#   the external interface of the machine.  For 
#   illustrative purposes, the IP address of 127.0.0.1 is 
#   used in this example.

my $filter;
Net::Pcap::compile(
    $object, 
    \$filter, 
    'port 80', 
    1, 
    $netmask
) && die 'Unable to compile packet capture filter';
Net::Pcap::setfilter($object, $filter) &&
    die 'Unable to set packet capture filter';

#   Set callback function and initiate packet capture loop

Net::Pcap::loop($object, -1, \&process_packet, '') ||
    die 'Unable to perform packet capture';

if($dumpfile) {
    Net::Pcap::pcap_dump_close($dumper);
}
Net::Pcap::close($object);

sub process_packet {
    my ($user_data, $header, $packet) = @_;

    # write dump data to dump file
    if($dumpfile) {
	Net::Pcap::pcap_dump($dumper, $header, $packet);
    }

    #   Strip ethernet encapsulation of captured packet 
    my $ether_data = NetPacket::Ethernet::strip($packet);

    #   Decode contents of TCP/IP packet contained within 
    #   captured ethernet packet

    my $ip = NetPacket::IP->decode($ether_data);
    my $tcp = NetPacket::TCP->decode($ip->{'data'});
    my $currFlowId = $utils->getFlowId($tcp, $ip);

    if ( $tcpFlow->isNewFlvResponse($tcp) ) {

	# init initializes total_bytes and ewma object
	$tcpFlow->init();

	#print STDERR "Key set to $currFlowId\n";
	my $startTime = $utils->getTimeFromHeader($header, {format => 'millisec'});
	$tcpFlow->setStartTime( $startTime );
	$log->init($startTime);

	#print STDERR "Found flv\n";
	$tcpFlow->setFlowId( $currFlowId );
	$tcpFlow->setNewFlvResponseFlag(1);
    }
    elsif( $tcpFlow->isVideoplaybackRequest($tcp) ) {
	my $currVideoId = $tcpFlow->getVideoId();
	my $videoId = $utils->extractVideoId( $tcp->{data} );
	if($videoId) {
	    if( !$currVideoId || $currVideoId ne $videoId ) {
		print STDERR "Video Id = $videoId\n";
		$tcpFlow->setVideoId($videoId);
		$tcpFlow->setVideoChangedStatus(1);
		$tcpFlow->setNewFlvResponseFlag(0);
	    }
	    elsif( $tcpFlow->getNewFlvResponseFlag() ){
		$tcpFlow->setVideoChangedStatus(0);
	    }
	}
    }
    elsif( $tcpFlow->isVideoFlowPacket($currFlowId) ) {
	$tcpFlow->setTotalBytes( $tcpFlow->getTotalBytes() + length($tcp->{data}) );
	my $currTime = $utils->getTimeFromHeader($header, {format => 'millisec'});
	#print STDERR "$currTime," , $tcpFlow->getTotalBytes(),',',$tcpFlow->getVideoId(),"\n";
	my $estBitrate = $tcpFlow->getEstimatedBitRate();
	if( $estBitrate && $log->isLogTime($currTime) ) {
	    my $currentPoint = $tcpFlow->getCurrentPoint();
	    my $currPlaybackTime = $tcpFlow->getCurrentPlaybackTime($currentPoint, {format=>'sec'});
	    my $estBuffer = $tcpFlow->estimateBuffer($estBitrate, $tcpFlow->getTotalBytes(), $currPlaybackTime);
	    my $videoId = $tcpFlow->getVideoId();
	    #printf( "%d,%.2f,%s,%.2f\n", $currTime, $estBuffer, $videoId, $currPlaybackTime );
	    printf( "%d,%.2f,%s\n", $currTime, $estBuffer, $videoId);
	    $log->setPrevLogTime($currTime);

	}
    }
    elsif( $tcpFlow->isSendingAck( $currFlowId ) ) {
	my $currTime = $utils->getTimeFromHeader($header, {format => 'millisec'});
	my $timeSinceStart = sprintf( "%.3f", $currTime - $tcpFlow->getStartTime() );
	#print STDERR "$currTime," . $tcpFlow->getTotalBytes() . "\n";
	$tcpFlow->setCurrentPoint($timeSinceStart, $tcpFlow->getTotalBytes());
	$tcpFlow->checkForKneePoint();
    }
}
