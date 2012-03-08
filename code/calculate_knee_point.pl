#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Geometry::Primitive::Point;
use KneePoint;

# Input mapping file
my $file = '';

# If need to calculate time buffered wrt playback time then is_time should be true
my $is_time = 0;
# If need to calculate bytes buffered wrt playback time then is_bytes should be true
my $is_bytes = 0;

GetOptions(
    "file=s" => \$file,
    "time"   => \$is_time,
    "bytes"  => \$is_bytes,
    );

# Error if both flags set or both flags unset.
if( ($is_time && $is_bytes) || (!$is_time && !$is_bytes) ) {
    die "Set either of the time or bytes flag.";
}

my $mappings = [];
open MFH, $file or die "Unable to open file $file";
while(<MFH>) {
    my ($t, $b, $T, $B) = split(', ', $_);

    # Push mappings from the file in an array
    if($is_time) {
	# push currently buffered time
	push @$mappings, [$t, $T-$t, $T];
    }
    elsif($is_bytes) {
	# push currently buffered bytes
	push @$mappings, [$t, $B-$b, $B];
    }
}
close(MFH);

# we have initial point but we still need to find another point where
# total time or bytes are buffered and start decreasing thereafter
my $initial_point = Geometry::Primitive::Point->new( {
    x => $mappings->[0][0],
    y => $mappings->[0][1],
} );

my $end_point_index = get_end_point_index( $mappings->[$#$mappings][2] );
my $end_point = Geometry::Primitive::Point->new( {
    x => $mappings->[$end_point_index][0],
    y => $mappings->[$end_point_index][1],
    } );
print STDERR $end_point->to_string(), "\n";
my $approx_line = Geometry::Primitive::Line->new( { start=>$initial_point, end=>$end_point } );
#$approx_line->start($initial_point);
#$approx_line->end($end_point);
my $knee = KneePoint->new($approx_line);
my $points = [];
for(my $i=0; $i <= $end_point_index; $i++) {
    push @$points, Geometry::Primitive::Point->new( { x => $mappings->[$i][0], y => $mappings->[$i][1] } );
}
my $knee_point = $knee->calculate($points);
print STDERR "Knee Point = ", $knee_point->to_string(), "\n";

my $buffer_line = Geometry::Primitive::Line->new( { start=>$knee_point, end=>$end_point } );
print 'Buffer Rate = ', $buffer_line->slope(), "\n";

sub get_end_point_index {
    my $max = shift;
    my $index = 0;
    while($index < @$mappings) {
	last if ( $mappings->[$index][2] == $max );
	$index++;
    }

    return $index;
}

