<?

/*
$event_type = $_GET["event_type"];
$system_time = $_GET["system_time"];
$playback_time = $_GET["playback_time"];
$eob_time = $_GET["eob_time"];
$playback_bytes = $_GET["playback_bytes"];
$eob_bytes = $_GET["eob_bytes"];
$status = $_GET["status"];
$quality = $_GET["quality"];
$bytes_total = $_GET["bytes_total"];
$time_total = $_GET["time_total"];
*/

// get array of values from browser
$data = json_decode($_POST['data']);
//print_r($data);

$link = mysql_connect("www-und.ida.liu.se", "priti063", "priti063258c");
if(!$link) {
	die( "Could not connect: " . mysql_error() );
}

$db_selected = mysql_select_db('priti063', $link);
if (!$db_selected) {
	die ('Can\'t use priyank_org : ' . mysql_error());
}

$ip = $_SERVER['REMOTE_ADDR'];
foreach($data as $row) {
	$query = "insert into player_metrics values (NULL, '$row[0]', $row[1], $row[2], $row[3], $row[4], $row[5], '$row[6]', '$row[7]', $row[8], $row[9], $row[10], '$row[11]', '$ip')";
//echo "$query\n";
	mysql_query($query);
}

mysql_close($link);

?>
