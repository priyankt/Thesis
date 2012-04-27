package Utils;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub getFlowId {
    my ($self, $tcp, $ip) = @_;
    my $flowId = $ip->{'src_ip'} . '-' . $tcp->{'src_port'} . '-' . $ip->{'dest_ip'} . '-' . $tcp->{'dest_port'};
    #my $flowId = $ip->{'dest_ip'} . '-' . $tcp->{'dest_port'};
    return $flowId;
}

sub getTimeFromHeader {
    my ($self, $header, $opts) = @_;
    my $time = '';
    if( $opts->{format} =~ /^millisec/i ) {
	$time = sprintf( "%.3f",($header->{tv_sec}*1000) + ($header->{tv_usec}/1000) );
    }
    if($opts->{format} =~ /^sec/) {
	$time = sprintf( "%.3f", $header->{tv_sec} + ($header->{tv_usec}/1000000) );
    }
    return $time;
}

sub extractVideoId {
    my ($self, $request) = @_;
    my $id = 0;
    if( $request =~ /&?id=([a-zA-Z0-9]{16})&?/ ) {
	$id = $1;
    }
    else {
	print STDERR "STRANGE: videoplayback request but no hex id matched\n";
    }
    if( $request =~ /&?range=(\d+-\d+)&?/ ) {
	print 'Range = ', $1, "\n";
    }

    return $id;
}

1;
