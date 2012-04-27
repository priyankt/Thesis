package GroundTruth;

use strict;
use warnings;
use DBObject;

sub new {
    my $class = shift;
    my $db = new DBObject();
    my $self = {
	db => $db,
    };
    bless $self, $class;
    return $self;
}

sub getRecord {
    my ($self, $systime_ms) = @_;
    my $db = $self->{db};
    my $query = "select playback_time, eob_bytes, url from player_metrics where system_time <= $systime_ms order by system_time desc limit 1";
    my $rec = $db->{dbh}->selectrow_hashref($query) or die "Failed to query database";
    return $rec;
}

sub close {
    my $self = shift;
    $self->{db}->close();
}

1;
