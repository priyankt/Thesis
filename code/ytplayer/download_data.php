<?

$fname = $_GET["filename"];
$link = mysql_connect("www-und.ida.liu.se", "priti063", "priti063258c");
if(!$link) {
	die( "Could not connect: " . mysql_error() );
}

$db_selected = mysql_select_db('priti063', $link);
if (!$db_selected) {
	die ('Can\'t use priyank_org : ' . mysql_error());
}

$query = "select system_time, playback_time, eob_bytes, status, quality, bytes_total, time_total, video_start_bytes from player_metrics";
$result = mysql_query($query);
mysql_close($link);

header('Content-type: text/plain');
header("Content-Disposition: attachment; filename=$fname");

echo "system_time, playback_time, eob_bytes, status, quality, bytes_total, time_total, video_start_bytes\n";
while($row = mysql_fetch_array($result)) {
  echo $row['system_time'] . "," . $row['playback_time'] . "," . $row['eob_bytes'] . "," . $row['status'] . "," . $row['quality'] . "," . $row['bytes_total'] . "," . $row['time_total'] . "," . $row['video_start_bytes'] . "\n";
}

?>
