-- 
 -- Script para registrar as informações estatisticas das Filas
 -- 
 
 USE asteriskcdrdb;
 
 DROP TABLE IF EXISTS queue_log;
 CREATE TABLE IF NOT EXISTS queue_log (
 	id bigint(255) unsigned NOT NULL AUTO_INCREMENT,
 	time varchar(26) NOT NULL,
 	callid varchar(40) NOT NULL,
 	queuename varchar(20) NOT NULL,
 	agent varchar(20) NOT NULL,
 	event varchar(20) NOT NULL,
 	data varchar(100) NOT NULL,
 	data1 varchar(40) NOT NULL,
 	data2 varchar(40) NOT NULL,
 	data3 varchar(40) NOT NULL,
 	data4 varchar(40) NOT NULL,
 	data5 varchar(40) NOT NULL,
 	created timestamp NOT NULL,
 	PRIMARY KEY (id),
 	KEY queue (queuename),
 	KEY event (event)
 ) DEFAULT CHARSET=utf8;
 
 DROP TABLE IF EXISTS agent_status;
 CREATE TABLE IF NOT EXISTS `agent_status` (
 	`agentId` varchar(40) NOT NULL,
 	`agentName` varchar(40) DEFAULT NULL,
 	`agentStatus` varchar(30) DEFAULT NULL,
 	`timestamp` timestamp NULL DEFAULT NULL,
 	`callid` varchar(32) DEFAULT NULL,
 	`queue` varchar(20) DEFAULT NULL,
 	PRIMARY KEY (`agentId`),
 	KEY `agentName` (`agentName`),
 	KEY `agentStatus` (`agentStatus`,`timestamp`,`callid`),
 	KEY `queue` (`queue`)
 ) DEFAULT CHARSET=utf8;
 
 DROP TABLE IF EXISTS call_status;
 CREATE TABLE IF NOT EXISTS `call_status` (
 	`callId` varchar(32) DEFAULT NULL,
 	`callerId` varchar(13) NOT NULL,
 	`status` varchar(30) NOT NULL,
 	`timestamp` timestamp NULL DEFAULT NULL,
 	`queue` varchar(25) NOT NULL,
 	`agent` varchar(32) NOT NULL,
 	`position` varchar(11) NOT NULL,
 	`originalPosition` varchar(11) NOT NULL,
 	`holdtime` varchar(11) NOT NULL,
 	`keyPressed` varchar(11) NOT NULL,
 	`callduration` int(11) NOT NULL,
 	PRIMARY KEY (`callId`),
 	KEY `callerId` (`callerId`),
 	KEY `status` (`status`),
 	KEY `timestamp` (`timestamp`),
 	KEY `queue` (`queue`),
 	KEY `position` (`position`,`originalPosition`,`holdtime`)
 ) DEFAULT CHARSET=utf8;
 
 CREATE TABLE IF NOT EXISTS `queue_log_processed` (
 	`recid` int(10) unsigned NOT NULL AUTO_INCREMENT,
 	`origid` int(10) unsigned NOT NULL,
 	`callid` varchar(32) NOT NULL,
 	`queuename` varchar(32) NOT NULL,
 	`agentdev` varchar(32) NOT NULL,
 	`event` varchar(32) NOT NULL,
 	`data1` varchar(128) NOT NULL,
 	`data2` varchar(128) NOT NULL,
 	`data3` varchar(128) NOT NULL,
 	`datetime` datetime NOT NULL,
 	PRIMARY KEY (`recid`),
 	KEY `data1` (`data1`),
 	KEY `data2` (`data2`),
 	KEY `data3` (`data3`),
 	KEY `event` (`event`),
 	KEY `queuename` (`queuename`),
 	KEY `callid` (`callid`),
 	KEY `datetime` (`datetime`),
 	KEY `agentdev` (`agentdev`),
 	KEY `origid` (`origid`)
 ) DEFAULT CHARSET=utf8;
 
 -- 
 -- Triggers : Abaixo seguem as triggers que irao popular as tabelas criadas acima
 -- 
 DROP TRIGGER IF EXISTS `asteriskcdrdb`.update_processed;
 DELIMITER //
 CREATE TRIGGER `asteriskcdrdb`.`update_processed` AFTER INSERT ON `asteriskcdrdb`.`queue_log`
 FOR EACH ROW BEGIN
 	INSERT INTO queue_log_processed (callid,queuename,agentdev,event,data1,data2,data3,datetime)
 	VALUES (NEW.callid,NEW.queuename,NEW.agent,NEW.event,NEW.data1,NEW.data2,NEW.data3,NEW.time);
 END
 //
 DELIMITER ;
 
 DROP TRIGGER IF EXISTS `asteriskcdrdb`.`bi_queueEvents`;
 DELIMITER //
 CREATE TRIGGER `asteriskcdrdb`.`bi_queueEvents` BEFORE INSERT ON `asteriskcdrdb`.`queue_log`
 FOR EACH ROW BEGIN
 /* https://wiki.asterisk.org/wiki/display/AST/Queue+Logs */
 	IF NEW.event = 'ADDMEMBER' THEN
 		INSERT INTO agent_status (agentId,agentStatus,timestamp,callid,queue) VALUES   (NEW.agent,'READY',NEW.time,NULL,NEW.queuename) ON DUPLICATE KEY UPDATE agentStatus = "READY", timestamp = NEW.time, callid = NULL, queue  = NEW.queuename;
 	ELSEIF NEW.event = 'REMOVEMEMBER' THEN
 		INSERT INTO `agent_status` (agentId,agentStatus,timestamp,callid,queue) VALUES  (NEW.agent,'LOGGEDOUT',NEW.time,NULL,NEW.queuename) ON DUPLICATE KEY UPDATE agentStatus = "LOGGEDOUT", timestamp = NEW.time, callid =  NULL, queue = NEW.queuename;
 	ELSEIF NEW.event = 'AGENTLOGIN' THEN
 		INSERT INTO `agent_status` (agentId,agentStatus,timestamp,callid,queue) VALUES  (NEW.agent,'LOGGEDIN',NEW.time,NULL,NEW.queuename) ON DUPLICATE KEY UPDATE agentStatus = "LOGGEDIN", timestamp = NEW.time, callid = NULL, queue = NEW.queuename;
 	ELSEIF NEW.event = 'AGENTLOGOFF' THEN
 		INSERT INTO `agent_status` (agentId,agentStatus,timestamp,callid,queue) VALUES (NEW.agent,'LOGGEDOUT',NEW.time,NULL,NEW.queuename) ON DUPLICATE KEY UPDATE agentStatus = "LOGGEDOUT", timestamp = NEW.time, callid = NULL, queue = NEW.queuename;
 	ELSEIF NEW.event = 'PAUSE' THEN
 		INSERT INTO agent_status (agentId,agentStatus,timestamp,callid,queue) VALUES  (NEW.agent,'PAUSE',NEW.time,NULL,NEW.queuename) ON DUPLICATE KEY UPDATE agentStatus = "PAUSE", timestamp = NEW.time, callid = NULL, queue = NEW.queuename;
 	ELSEIF NEW.event = 'UNPAUSE' THEN
 		INSERT INTO `agent_status` (agentId,agentStatus,timestamp,callid,queue) VALUES (NEW.agent,'READY',NEW.time,NULL,NEW.queuename) ON DUPLICATE KEY UPDATE agentStatus = "READY", timestamp = NEW.time, callid = NULL, queue = NEW.queuename;
 	ELSEIF NEW.event = 'ENTERQUEUE' THEN
 		REPLACE INTO `call_status` VALUES
 		(NEW.callid,NEW.data2,
 		'inQue',
 		NEW.time,
 		NEW.queuename,
 		NULL,
 		NULL,
 		NULL,
 		NULL,
 		NULL,
 		0);
 	ELSEIF NEW.event = 'CONNECT' THEN
 		UPDATE `call_status` SET
 		callid = NEW.callid,
 		status = NEW.event,
 		timestamp = NEW.time,
 		queue = NEW.queuename,
 		holdtime = NEW.data1,
 		agent = NEW.agent
 		where callid = NEW.callid;
 		INSERT INTO agent_status (agentId,agentStatus,timestamp,callid,queue) VALUES
 		(NEW.agent,NEW.event,
 		NEW.time,
 		NEW.callid,
 		NEW.queuename)
 		ON DUPLICATE KEY UPDATE
 		agentStatus = NEW.event,
 		timestamp = NEW.time,
 		callid = NEW.callid,
 		queue = NEW.queuename;
 	ELSEIF NEW.event in ('COMPLETECALLER','COMPLETEAGENT') THEN
 		UPDATE `call_status` SET
 		callid = NEW.callid,
 		status = NEW.event,
 		timestamp = NEW.time,
 		queue = NEW.queuename,
 		originalPosition = NEW.data3,
 		holdtime = NEW.data1,
 		callduration = NEW.data2,
 		agent = NEW.agent
 		where callid = NEW.callid;
 		INSERT INTO agent_status (agentId,agentStatus,timestamp,callid,queue) VALUES  (NEW.agent,NEW.event,NEW.time,NULL,NEW.queuename) ON DUPLICATE KEY UPDATE agentStatus = "READY", timestamp = NEW.time, callid = NULL, queue = NEW.queuename;
 	ELSEIF NEW.event in ('TRANSFER') THEN
 		UPDATE `call_status` SET
 		callid = NEW.callid,
 		status = NEW.event,
 		timestamp = NEW.time,
 		queue = NEW.queuename,
 		holdtime = NEW.data1,
 		callduration = NEW.data3,
 		agent = NEW.agent
 		where callid = NEW.callid;
 		INSERT INTO agent_status (agentId,agentStatus,timestamp,callid,queue) VALUES
 		(NEW.agent,'READY',NEW.time,NULL,NEW.queuename)
 		ON DUPLICATE KEY UPDATE
 		agentStatus = "READY",
 		timestamp = NEW.time,
 		callid = NULL,
 		queue = NEW.queuename;
 	ELSEIF NEW.event in ('ABANDON','EXITEMPTY') THEN
 		UPDATE `call_status` SET
 		callid = NEW.callid,
 		status = NEW.event,
 		timestamp = NEW.time,
 		queue = NEW.queuename,
 		position = NEW.data1,
 		originalPosition = NEW.data2,
 		holdtime = NEW.data3,
 		agent = NEW.agent
 		where callid = NEW.callid;
 	ELSEIF NEW.event = 'EXITWITHKEY' THEN
 		UPDATE `call_status` SET
 		callid = NEW.callid,
 		status = NEW.event,
 		timestamp = NEW.time,
 		queue = NEW.queuename,
 		position = NEW.data2,
 		keyPressed = NEW.data1,
 		agent = NEW.agent
 		where callid = NEW.callid;
 	ELSEIF NEW.event = 'EXITWITHTIMEOUT' THEN
 		UPDATE `call_status` SET
 		callid = NEW.callid,
 		status = NEW.event,
 		timestamp = NEW.time,
 		queue = NEW.queuename,
 		position = NEW.data1,
 		agent = NEW.agent
 		where callid = NEW.callid;
 	END IF;
 END
 //
 DELIMITER ;
