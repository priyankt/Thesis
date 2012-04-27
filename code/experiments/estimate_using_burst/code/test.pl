#!/usr/bin/perl

use strict;
use warnings;

use VideoTagLogFile;
use DBObject;
use DBI;

my $file = $ARGV[0];

my $db = new DBObject();

my $dbh = $db->{dbh};
my $q = "select * from player_metrics where url = 'KQ6zr6kCPj8' and experiment_id is null order by system_time";
my $recs = $dbh->selectall_arrayref( $q, { Slice => {} } );
$db->close();

my $start_time = $recs->[0]{system_time};
foreach(@$recs) {
    #print $_->{eob_bytes}, "\n";
    my $elapsed_time = sprintf( "%.3f", ($_->{system_time} - $start_time)/1000 );
    my $buffered_bytes = $_->{eob_bytes}/1000;
    print "$elapsed_time,$buffered_bytes\n";
}

__END__
my $tagObj = new VideoTagLogFile($file);
$tagObj->setInterpolate();
my $db = new DBObject();

my $dbh = $db->{dbh};
my $q = "select * from player_metrics where url = 'Loj5C1GVQBw' and experiment_id is null";
my $recs = $dbh->selectall_arrayref( $q, { Slice => {} } );
$db->close();

my $start_time = $recs->[0]{system_time};
foreach(@$recs) {
    #print $_->{eob_bytes}, "\n";
    my $elapsed_time = sprintf( "%.3f", ($_->{system_time} - $start_time)/1000 );
    my $buffered_time = $tagObj->getTime( $_->{eob_bytes} );
    $buffered_time /= 1000;
    $buffered_time = sprintf("%.3f", $buffered_time);
    print "$elapsed_time,$buffered_time\n";
}


