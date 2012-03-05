<?

$link = mysql_connect("www-und.ida.liu.se", "priti063", "priti063258c");
if(!$link) {
	die( "Could not connect: " . mysql_error() );
}

$db_selected = mysql_select_db('priti063', $link);
if (!$db_selected) {
	die ('Can\'t use priyank_org : ' . mysql_error());
}

$query = "truncate table player_metrics";
$result = mysql_query($query);
mysql_close($link);

?>
