package EWMA;

use strict;
use warnings;

use constant ALPHA => 0.30;
use constant DALPHA => 0.30;
use constant FACTOR => 40;

sub new {
    my ($class) = @_;
    my $self = {
	_arr => 0,
	_arrvar => 0,
	_threshold => 0,
    };
    bless $self, $class;
    return $self;
}

sub calculateThreshold {
    my ($self, $arrivalTime) = @_;

    my $arr = $self->get_arr();
    $arr =  ( $arr ? ALPHA * $arrivalTime + (1 - ALPHA) * $arr : $arrivalTime);
    $arr = sprintf( "%.3f", $arr);
	
    # calculate the deviation from average inter arrival time
    my $deviation =  abs($arrivalTime - $arr);
    $deviation = sprintf( "%.3f", $deviation);

    # EWMA for deviation from average arrival
    my $arrvar = $self->get_arrvar();
    $arrvar =  ($arrvar ? DALPHA * $deviation + (1 - DALPHA) * $arrvar : $arr);
    $arrvar = sprintf( "%.3f", $arrvar);
	
    # update wait threshold
    my $threshold = $arr + FACTOR * $arrvar;
    $threshold = sprintf( "%.3f", $threshold);

    $self->set_arr($arr);
    $self->set_arrvar($arrvar);
    $self->set_threshold($threshold);
}

sub set_arr {
    my ($self, $arr) = @_;
    $self->{_arr} = $arr;
}

sub set_arrvar {
    my ($self, $arrvar) = @_;
    $self->{_arrvar} = $arrvar;
}

sub set_threshold {
    my ($self, $threshold) = @_;
    $self->{_threshold} = $threshold;
}

sub get_arr {
    my ($self) = @_;
    return $self->{_arr};
}

sub get_arrvar {
    my ($self) = @_;
    return $self->{_arrvar};
}

sub getThreshold {
    my ($self) = @_;
    return $self->{_threshold};
}

1;
