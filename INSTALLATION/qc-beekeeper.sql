CREATE TABLE `qc_apiaries` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`citizenid` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
	`properties` TEXT NOT NULL COLLATE 'utf8mb4_general_ci',
	`apiarieid` INT(11) NOT NULL,
	PRIMARY KEY (`id`) USING BTREE
) COLLATE='utf8mb4_general_ci' ENGINE=InnoDB;
