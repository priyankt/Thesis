package KneePoint;

use strict;
use warnings;

use Geometry::Primitive::Point;
use Geometry::Primitive::Line;
use CGI::Carp;

sub new {
    my ($class, $line) = @_;
    my $self = { };
    if( $line->isa("Geometry::Primitive::Line") ) {
	$self->{_line} = $line
    }
    else {
	croak "line is not a Geometry::Primitive::Line object";
    }

    bless $self, $class;
    return $self;
}

sub add_line {
    my ($self, $line) = @_;

    # Check if $line is an object of type Geometry::Primitive::Line
    if( !$line->isa("Geometry::Primitive::Line") ) {
	croak "Not a Geometry::Primitive::Line";
    }
    $self->{_line} = $line;
}

sub calculate {
    my ($self, $points) = @_;
    # check if line is set
    if( !exists $self->{_line} && !$self->{_line}->isa("Geometry::Primitive::Line")) {
	croak "Line is not added. use add_line()";
    }

    my $knee_point = undef;
    my $max_distance = 0;
    foreach my $point (@$points) {
	if( !$point->isa("Geometry::Primitive::Point") ) {
	    croak "Not a Geometry::Primitive::Point object";
	}
	# calculate perpendicular distance from current point
	# to line
	my $distance = $self->_get_distance($point);
	if( $distance > $max_distance ) {
	    $max_distance = $distance;
	    $knee_point = $point;
	}
    }

    return $knee_point;
}

sub _get_distance {
    my ($self, $point) = @_;
    
    my $slope = $self->get_line()->slope();
    my $C = $self->get_line()->y_intercept();

    # Formula used here can be found at http://www.intmath.com/plane-analytic-geometry/perpendicular-distance-point-line.php
    return abs( ($slope*$point->x) + (-1*$point->y) + $C ) / ( sqrt( ($slope^2)+ (-1^2) ) );
}

sub get_line {
    my ($self) = @_;
    return $self->{_line};
}

1;
