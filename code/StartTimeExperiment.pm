package StartTimeExperiment;

use strict;
use warnings;
use JSON;
use Chart::Gnuplot;
use Data::Dumper;

use constant LOAD_EVENT => 'load';
use constant START_EVENT => 'start';

sub new {
    my ($class, $opts) = @_;

    my $self = {
	_index => 0,
	_num_video => 0,
	_current_video_id => '',
	_graph => [],
	max_x => 0,
	max_y => 0
    };
    if( $opts->{player_file} ) {
	if($opts->{format} eq 'json') {
	    open JFH, $opts->{player_file} or die "Unable to open file " . $opts->{player_file};
	    my $json_str = <JFH>;
	    close(JFH);
	    my $json = JSON->new->allow_nonref;
	    $self->{data} = $json->decode($json_str);
	}
	else {
	    die "NO JSON: Only json format is supported till now.";
	}
    }
    $self->{_current_video_id} = $self->{data}[$self->{_index}]{url};
    while(my ($k, $v) = each(%$opts)) {
	$self->{$k} = $v;
    }

    bless $self, $class;
}

sub load_time {
    my $self = shift;
    while( $self->event() ne LOAD_EVENT ) {
	$self->next();
    }
    return $self->{data}[$self->_index()]{system_time};
}

sub start_time {
    my $self = shift;
    while($self->event ne START_EVENT) {
	if( $self->_current_video_id() ne $self->url() ) {
	    die "NO START: No start event for corresponding load event for video" . $self->current_video_id();
	}
	$self->next();
    }
    return $self->{data}[$self->_index()]{system_time};
}

sub next {
    my $self = shift;
    my $index = $self->_index()+1;
    if( $index >= $self->_total_experiments() ) {
	die "END: No more experiments";
    }
    my $prev_video_id = $self->_current_video_id();
    $self->_set_index( $index);
    if( $prev_video_id ne $self->_current_video_id() ) {
	$self->_set_num_video($self->_num_video()+1);
    }
    $self->_set_current_video_id($self->url());
}

sub url {
    my $self = shift;
    my $index = $self->_index();
    return $self->{data}[$index]{url};
}

sub event {
    my $self = shift;
    return $self->{data}[$self->_index()]{event_type};
}

sub buffered_bytes {
    my ($self, $opts) = @_;

    my $bytes = $self->{data}[$self->_index()]{eob_bytes};
    if( $opts->{kilobytes} ) {
	$bytes /= 1024;
    }

    return $bytes;
}

sub add_to_graph {
    my ($self, $x, $y) = @_;
    push @{$self->{_graph}}, [$x, $y];
    if($self->{max_x} < $x) {
	$self->{max_x} = $x;
    }
    if($self->{max_y} < $y) {
	$self->{max_y} = $y;
    }
}

sub plot_graph {
    my ($self, $outfile) = @_;

    my $dataset = Chart::Gnuplot::DataSet->new(
	points => $self->{_graph},
	style => 'points',
	);

    my $chart = Chart::Gnuplot->new(
	output => "charts/$outfile",
	title  => 'Player start time v/s buffered bytes',
	xrange => [0, $self->{max_x}],
	yrange => [0, $self->{max_y}],
	xlabel => "time (millisec)",
	ylabel => "buffered bytes (KB)",
	);

    $chart->plot2d($dataset);
}

sub _num_video {
    my $self = shift;
    return $self->{_num_video};
}

sub _set_num_video {
    my ($self, $num) = @_;
    $self->{_num_video} = $num;
}

sub _total_experiments {
    my $self = shift;
    return scalar(@{$self->{data}});
}

sub _index {
    my $self = shift;
    return $self->{_index};
}

sub _set_index {
    my ($self, $index) = @_;
    $self->{_index} = $index;    
}

sub _current_video_id {
    my $self = shift;
    return $self->{_current_video_id};
}

sub _set_current_video_id {
    my ($self, $video_id)  = @_;
    if(!$video_id) {
	die "NO VIDEO ID: Video id not provided to _set_current_video_id";
    }
    $self->{_current_video_id} = $video_id; 
}

1;
