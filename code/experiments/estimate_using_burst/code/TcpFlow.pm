package TcpFlow;

use strict;
use warnings;
use Point;
use ewma;

use constant DATA_RATE_THRES => 200;

sub new {
    my $class = shift;
    my $self = {
	_flow_id => '',
	_total_bytes => 0,
	_starttime => 0,
	_ewma => undef,
	_curr_point => undef,
	_prev_point => undef,
	_video_id => 0,
	_est_bit_rate => 0,
	_knee_point => undef,
	_video_changed_status => 0,
	_prev_data_rate => 0,
    };
    bless $self, $class;
    return $self;
}

sub init {
    my ($self) = @_;
    $self->setTotalBytes(0);
    $self->{_prev_data_rate} = 0;
    $self->{_ewma} = new EWMA();
    $self->{_curr_point} = new Point(0,0);
    $self->{_prev_point} = new Point(0,0);
    $self->{_est_bit_rate} = 0;
    $self->{_flv_response_flag} = 0;
    $self->{_knee_point} = new Point(0,0);
}

sub isNewFlvResponse {
    my ($self, $tcp) = @_;
    my $newFlv = 0;
    if( $tcp->{data} =~ /Content-type: video\/x-flv/i && $tcp->{data} !~ /Content-Length: 0/i ) {
	# TODO: This is an ugly fix for range request. New range request for same video
	# should not be counted as new video Flv Response. Need to fix this later
	#if ( $tcp->{data} !~ /Content-Length: 1781760/i ) {
	if( $self->getVideoChangedStatus() ) {
	    $newFlv = 1;
	}
    }
    return $newFlv;
}

sub setNewFlvResponseFlag {
    my ($self, $flag) = @_;
    $self->{_flv_response_flag} = $flag;
}

sub getNewFlvResponseFlag {
    my ($self) = @_;
    return $self->{_flv_response_flag};
}

sub setVideoChangedStatus {
    my ($self, $status) = @_;
    $self->{_video_changed_status} = $status;
}

sub getVideoChangedStatus {
    my ($self) = @_;
    return $self->{_video_changed_status};
}

sub getFlowId {
    my ($self) = @_;
    return $self->{_flow_id};
}

sub setFlowId {
    my ($self, $flowId) = @_;
    $self->{_flow_id} = $flowId;
}

sub setVideoId {
    my ($self, $videoId) = @_;
    $self->{_video_id} = $videoId;
}

sub getVideoId {
    my ($self) = @_;
    return $self->{_video_id};
}

sub isVideoplaybackRequest {
    my ($self, $tcp) = @_;
    my $playbackReq = 0;
    if ( $tcp->{data} =~ /GET\s\/videoplayback\?/i ) {
	$playbackReq = 1;
    }
    return $playbackReq;
}

sub setTotalBytes {
    my ($self, $bytes) = @_;
    $self->{_total_bytes} = $bytes;
}

sub getTotalBytes {
    my ($self) = @_;
    return $self->{_total_bytes};
}

sub checkForKneePoint {
    my ($self) = @_;
    my $currentPoint = $self->getCurrentPoint();
    my $previousPoint = $self->getPreviousPoint();
    my $currentArrivalTime = $self->getCurrentArrivalTime( $currentPoint->get_x() );
    my $threshold = $self->getThreshold();
    if( $threshold > 0 && $currentArrivalTime > $threshold ) {
	# now currentPoint is a potential kneePoint
	if( $self->kneeExists() ) {
	    my $kneePoint = $self->getKneePoint();
	    my $R = $self->getDataRate( $kneePoint, $previousPoint );
	    my $dataRateThres = $self->getDataRateThres();
	    #print STDERR "R = $R, $threshold, ", $previousPoint->get_x(), ', ', $previousPoint->get_y(), "\n";
	    if( $R < $dataRateThres ) {
		#if( !$self->getEstimatedBitRate() ) {
		    my $estBitrate = $self->estimateBitrate($R);
		    #print STDERR "Knee Point = ", $kneePoint->get_x(), ', ', $kneePoint->get_y(), "\n";
		    #print STDERR "Estimated bitrate = $estBitrate\n";
		    $self->setEstimatedBitRate( $estBitrate );
		#}
	    }
	    else {
		$self->setKneePoint( $previousPoint );
		$self->setPrevDataRate($R);
		# uncomment below line if multiple knee points allowed
		# need to chk what if data rate falls down and comes up again
		#$self->setEstimatedBitRate(0);
	    }
	}
	else {
	    $self->setKneePoint( $previousPoint );
	}
    }
    $self->calculateThreshold( $currentArrivalTime );
}

sub setPrevDataRate {
    my ($self, $rate) = @_;
    $self->{_prev_data_rate} = $rate;
}

sub getPreviousDataRate {
    my ($self) = @_;
    return $self->{_prev_data_rate};
}

sub getDataRateThres {
    my ($self) = @_;
    my $thres = DATA_RATE_THRES;
    my $prevDataRate = $self->getPreviousDataRate();
    if($prevDataRate) {
	$thres = $prevDataRate/30;
    }
    return sprintf("%.3f", $thres);
}

sub getEstimatedBitRate {
    my ($self) = @_;
    return $self->{_est_bit_rate};
}

sub setEstimatedBitRate {
    my ($self, $bitRate) = @_;
    $self->{_est_bit_rate} = $bitRate;
}

sub isSendingAck {
    my ($self, $flowId) = @_;
    my $currFlowId = $self->getFlowId();
    my @flowElements = split('-', $flowId);
    my @currFlowElements = split('-', $currFlowId);

    #return $currFlowId eq $self->reverseFlowId();
    return ($currFlowId && ($currFlowElements[0] eq $flowElements[2] && $currFlowElements[1] eq $flowElements[3]));
}

sub reverseFlowId {
    my ($self) = @_;
    my $flowId = $self->getFlowId();
    my $reverseFlowId = '';
    if($flowId) {
	my @elements = split('-', $flowId);
	$reverseFlowId = "$elements[2]-$elements[3]-$elements[0]-$elements[1]";
    }
    return $reverseFlowId;
}

sub getCurrentPlaybackTime {
    my ($self, $currentPoint, $opts) = @_;
    my $playbackTime = 0;
    if($opts->{format} =~ /^millisec/i) {
	$playbackTime = $currentPoint->get_x();
    }
    elsif($opts->{format} =~ /^sec/i) {
	$playbackTime = $currentPoint->get_x()/1000;
    }
    return $playbackTime;
}

sub getDataRate {
    my ($self, $prevPoint, $currPoint) = @_;
    my $dataRate = 0;
    if( $prevPoint->get_x() - $currPoint->get_x() != 0 ) {
	$dataRate = ( $currPoint->get_y() - $prevPoint->get_y() ) / ( $currPoint->get_x() - $prevPoint->get_x() );
    }
    return $dataRate;
}

sub calculateThreshold {
    my ($self, $arrivalTime) = @_;
    my $ewma = $self->getEWMA();
    $ewma->calculateThreshold($arrivalTime);
}

sub estimateBuffer {
    my ($self, $estBitrate, $bytes, $currPlaybackTime) = @_;

    # estBitrate is in bytes per second & currPlaybackTime in seconds
    my $buffer = ($bytes/$estBitrate) - $currPlaybackTime;

    return $buffer;
}

sub estimateBitrate {
    my ($self, $R) = @_;
    my $kneePoint = $self->getKneePoint();
    my $currentPoint = $self->getCurrentPoint();
    #my $initiallyBuffered = 40 + (($currentPoint->get_x() - $kneePoint->get_x())/1000);
    #my $initiallyBuffered = 40 + (($currentPoint->get_x() - $self->getPreviousPoint()->get_x())/1000);
    my $initiallyBuffered = 40;
    #print "Initially Buffered = $initiallyBuffered\n";
    my $estBitrate = $kneePoint->get_y()/$initiallyBuffered; # in bytes per second
    return sprintf("%.3f", $estBitrate);
}

sub getThreshold {
    my ($self) = @_;
    my $ewma = $self->getEWMA();
    return sprintf( "%.3f", $ewma->getThreshold() );
}

sub setKneePoint {
    my ($self, $kneePoint) = @_;
    my $oldKneePoint = $self->getKneePoint();
    $oldKneePoint->set_xy( $kneePoint->get_x(), $kneePoint->get_y() );
}

sub getKneePoint {
    my ($self) = @_;
    return $self->{_knee_point};
}

sub kneeExists() {
    my ($self) = @_;
    my $kneePoint = $self->getKneePoint();
    return $kneePoint->get_x() && $kneePoint->get_y();
}

sub getCurrentArrivalTime {
    my ($self, $currentTime) = @_;
    my $prevPoint = $self->getPreviousPoint();
    return sprintf( "%.3f", $currentTime - $prevPoint->get_x() );
}

sub setStartTime {
    my ($self, $time) = @_;
    $self->{_starttime} = $time;
}

sub getStartTime {
    my ($self) = @_;
    return $self->{_starttime};
}

sub getEWMA {
    my ($self) = @_;
    return $self->{_ewma};
}

sub isVideoFlowPacket {
    my ($self, $flowId) = @_;
    my $currFlowId = $self->getFlowId();
    my @flowElements = split('-', $flowId);
    my @currFlowElements = split('-', $currFlowId);
    my $val = 0;
    #if( $currFlowId && $currFlowId eq $flowId ) {
    if( $currFlowId && ($flowElements[0] eq $currFlowElements[0] && $flowElements[1] eq $currFlowElements[1])) {
	$val = 1;
    }
    return $val;
}

sub getCurrentPoint {
    my ($self) = @_;
    return $self->{_curr_point};
}

sub getPreviousPoint {
    my ($self) = @_;
    return $self->{_prev_point};
}

sub setCurrentPoint {
    my ($self, $x, $y) = @_;
    my $currPoint = $self->getCurrentPoint();
    my $prevPoint = $self->getPreviousPoint();
    $prevPoint->set_xy( $currPoint->get_x(), $currPoint->get_y() );
    $currPoint->set_xy( $x, $y );
}

1;
