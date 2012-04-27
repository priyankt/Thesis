package Point;

use strict;
use warnings;

sub new {
    my ($class, $x, $y) = @_;
    my $self = {
	_x => $x,
	_y => $y,
    };
    bless $self, $class;
    return $self;
}

sub get_x {
    my ($self) = @_;
    return $self->{_x};
}

sub get_y {
    my ($self) = @_;
    return $self->{_y};
}

sub set_xy {
    my ($self, $x, $y) = @_;
    $self->{_x} = $x;
    $self->{_y} = $y;
}

1;
