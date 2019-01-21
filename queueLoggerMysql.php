<?php
/**
* queueLoggerMysql.php : PHP Queue Log to MySQL (table queue_log)
* Website: http://fksapiens.com.br/
*
* Copyright (c) 1999 - 2017 Franklin Farias <franklin@fksapiens.com.br>
* All Rights Reserved.
*
* This software is released under the terms of the GNU Lesser General Public License v2.1
* A copy of which is available from http://www.gnu.org/copyleft/lesser.html
*
* We would be happy to list your phpagi based application on the queueLoggerMysql
* website.  Drop me an Email if you'd like us to list your program.
* 
*
* Written for PHP 5.4, should work with older PHP 4.x versions.
*
* Please submit bug reports, patches, etc to http://wiki.fksapiens.com.br/
* Thanks. :)
*
*
* @package queueLoggerMysql
* @version 1.0
*/

define('PATH_QUEUE_LOG', '/var/log/asterisk/');

$db_host = "localhost";
$db_name = "asteriskcdrdb";
$db_user = "root";
$db_pass = "";

$db_connect = mysql_connect($db_host,$db_user,$db_pass) ;
mysql_select_db($db_name, $db_connect) or die(mysql_error()); 

$handle = fopen(PATH_QUEUE_LOG . "queue_log", "r");
if ($handle) {
    while (($line = fgets($handle)) !== false) {
		$array = explode("|",$line);
		$time = gmdate('Y-m-d H:i:s', $array[0]);
		$callId = $array[1];
		$queueName = $array[2];
		$agent = $array[3];
		$event = $array[4];
		$data1 = (count($array) > 5 ? $array[5] : );
		$data2 = (count($array) > 6 ? $array[6] : );
		$data3 = (count($array) > 7 ? $array[7] : );
		$data4 = (count($array) > 8 ? $array[8] : );
		$data5 = (count($array) > 9 ? $array[9] : );
		
		$rs = mysql_query("SELECT count(*) as qtd from queue_log WHERE time = '$time' AND callid = '$callId' AND queuename = '$queueName' AND event = '$event'", $db_connect);
		$row = mysql_fetch_assoc($rs);
		
		if ($row['qtd'] <= 0){
			$rs = mysql_query("INSERT INTO queue_log (time,callid,queuename,agent,event,data1,data2,data3,data4,data5) VALUES ('$time','$callId','$queueName','$agent','$event','$data1','$data2','$data3','$data4','$data5')", $db_connect);
			echo("Inserted: $line \n");
		} else {
			echo("Exists: $line \n");
		}
    }
    fclose($handle);
} else {
    echo("error opening the file.");
}

?>
