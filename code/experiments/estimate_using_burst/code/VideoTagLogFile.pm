package VideoTagLogFile;

# Given a video tag log file, returns an object representing the log file
# You can query log file object to get mappins

use strict;
use warnings;

sub new {
    my ($class, $logfile) = @_;
    if(!$logfile || $logfile eq '') {
	die "Invalid log file supplied.";
    }
    my $self = {
	interpolate => 0,
    };
    open FH, $logfile or die "Unable to open $logfile - $!";
    while(<FH>) {
	chomp $_;
	my @records = split(',', $_);
	push @{$self->{records}}, \@records;
    }
    close(FH);

    bless $self, $class;
    return $self;
}

sub getTime {
    my ($self, $bytes) = @_;
    my $time = 0;
    if( !interpolate() ) {
	foreach my $rec ( @{$self->{records}} ) {
	    if ( $rec->[4] > $bytes ) {
		last;
	    }
	    $time = $rec->[2];
	}
    }
    else {
	my $recs = $self->{records};
	for(my $i=0; $i < $#$recs; $i++) {
	    if($recs->[$i][4] > $bytes) {
		$time = $recs->[$i-1][4] + ( ( ($recs->[$i][2] - $recs->[$i-1][2])/($recs->[$i][4] - $recs->[$i-1][4]) ) * ($bytes - $recs->[$i-1][4]) );
		last;
	    }
	}
    }
    return $time;
}

sub setInterpolate {
    my $self = shift;
    $self->{interpolate} = 1;
}

sub interpolate {
    my $self = shift;
    return $self->{interpolate};
}

1;
