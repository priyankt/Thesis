package Log;

use strict;
use warnings;

sub new {
    my ($class, $interval) = @_;
    my $self = {
	_prev_log_time => 0,
	_log_interval => $interval,
    };
    bless $self, $class;
    return $self;
}

sub init {
    my ($self, $time) = @_;
    $self->setPrevLogTime($time);
}

# Log interval in seconds
sub setLogInterval {
    my ($self, $interval) = @_;
    $self->{_log_interval} = $interval;
}

sub getLogInterval {
    my ($self) = @_;
    return $self->{_log_interval};
}

sub setPrevLogTime {
    my ($self, $logTime) = @_;
    $self->{_prev_log_time} = $logTime; # convert from millisec to sec
}

sub getPrevLogTime {
    my ($self) = @_;
    return $self->{_prev_log_time};
}

sub isLogTime {
    my ($self, $currTime) = @_;
    my $logTime = 0;
    if ( $currTime - $self->getPrevLogTime() > $self->getLogInterval() ) {
	$logTime = 1;
    }
    return $logTime;
}

1;
