-- Create your tables, views, functions and procedures here!
CREATE SCHEMA destruction;
USE destruction;

CREATE TABLE players (
     player_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
     first_name VARCHAR(30) NOT NULL,
     last_name VARCHAR(30) NOT NULL,
     email VARCHAR(50) NOT NULL
 );

CREATE TABLE characters (
    character_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    player_id INT UNSIGNED NOT NULL,
    name VARCHAR(30) NOT NULL,
    level INT UNSIGNED NOT NULL,
    CONSTRAINT characters_fk_players
        FOREIGN KEY (player_id)
        REFERENCES players (player_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);
 
CREATE TABLE winners (
    character_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL,
    CONSTRAINT winners_fk_characters
        FOREIGN KEY (character_id)
        REFERENCES characters (character_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);
 
CREATE TABLE character_stats (
    character_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    health INT UNSIGNED NOT NULL,
    armor INT UNSIGNED NOT NULL,
    CONSTRAINT character_stats_fk_characters
        FOREIGN KEY (character_id)
        REFERENCES characters (character_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);
 
CREATE TABLE teams (
    team_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL
 );
 
CREATE TABLE team_members (
    team_member_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    team_id INT UNSIGNED NOT NULL,
    character_id INT UNSIGNED NOT NULL,
    CONSTRAINT team_members_fk_teams
        FOREIGN KEY (team_id)
        REFERENCES teams (team_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT team_members_fk_characters
        FOREIGN KEY (character_id)
        REFERENCES characters (character_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);
 
CREATE TABLE items (
    item_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL,
    armor INT UNSIGNED NOT NULL,
    damage INT UNSIGNED NOT NULL
);
 
CREATE TABLE inventory (
    inventory_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    character_id INT UNSIGNED NOT NULL,
    item_id INT UNSIGNED NOT NULL,
    CONSTRAINT inventory_fk_characters
        FOREIGN KEY (character_id)
        REFERENCES characters (character_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT inventory_fk_items
        FOREIGN KEY (item_id)
        REFERENCES items (item_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);
 
CREATE TABLE equipped (
    equipped_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    character_id INT UNSIGNED NOT NULL,
    item_id INT UNSIGNED NOT NULL,
    CONSTRAINT equipped_fk_characters
        FOREIGN KEY (character_id)
        REFERENCES characters (character_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT equipped_fk_items
        FOREIGN KEY (item_id)
        REFERENCES items (item_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE OR REPLACE VIEW character_items AS
	SELECT c.character_id, c.name AS character_name, it.name AS item_name, it.armor, it.damage
		FROM characters c
			INNER JOIN inventory i
				ON c.character_id = i.character_id
			INNER JOIN items it
				ON i.item_id = it.item_id
	UNION
	SELECT c.character_id, c.name AS character_name, it.name AS item_name, it.armor, it.damage
		FROM characters c
			INNER JOIN equipped e
				ON c.character_id = e.character_id
			INNER JOIN items it
				ON e.item_id = it.item_id
	ORDER BY item_name ASC;

CREATE OR REPLACE VIEW team_items AS
	SELECT t.team_id, t.name AS team_name, it.name AS item_name, it.armor, it.damage
		FROM teams t
			INNER JOIN team_members tm
				ON t.team_id = tm.team_id
			INNER JOIN inventory i
				ON tm.character_id = i.character_id
			INNER JOIN items it
				ON i.item_id = it.item_id
	UNION
	SELECT t.team_id, t.name AS team_name, it.name AS item_name, it.armor, it.damage
		FROM teams t
			INNER JOIN team_members tm
				ON t.team_id = tm.team_id
			INNER JOIN equipped e
				ON tm.character_id = e.character_id
			INNER JOIN items it
				ON e.item_id = it.item_id
	ORDER BY item_name ASC;

DELIMITER ;;

CREATE FUNCTION armor_total(character_id INT UNSIGNED)
RETURNS INT UNSIGNED
DETERMINISTIC
BEGIN
	DECLARE gear_ac INT UNSIGNED;
	DECLARE natural_ac INT UNSIGNED;
	
	SELECT SUM(it.armor) INTO gear_ac
		FROM items it
			INNER JOIN equipped e
				ON it.item_id = e.item_id
		WHERE character_id = e.character_id;
	
	SELECT cs.armor INTO natural_ac
		FROM character_stats cs
		WHERE character_id = cs.character_id;
	
	RETURN gear_ac + natural_ac;
END ;;

CREATE PROCEDURE attack(defender_id INT UNSIGNED, weapon_id INT UNSIGNED)
BEGIN
    DECLARE armor INT UNSIGNED;
    DECLARE damage INT UNSIGNED;
    DECLARE result INT UNSIGNED;
    DECLARE hp INT SIGNED;
    
    SELECT armor_total(defender_id) INTO armor;
    
    SELECT it.damage INTO damage
		FROM equipped e
			INNER JOIN items it
				ON e.item_id = it.item_id
		WHERE e.equipped_id = weapon_id;
        
    SET result = damage - armor;
    
    SELECT cs.health INTO hp
		FROM character_stats cs
        	WHERE defender_id = cs.character_id;
    
    IF result > 0 THEN
		SET hp = hp - result;
			IF hp <= 0 THEN
				DELETE FROM characters WHERE character_id = defender_id;
			END IF;
		UPDATE character_stats SET health = hp WHERE character_id = defender_id;
    END IF;
    
END ;;

CREATE PROCEDURE equip(equip_id INT UNSIGNED)
BEGIN
    DECLARE char_id INT UNSIGNED;
    DECLARE item INT UNSIGNED;
    
    SELECT i.character_id INTO char_id
		FROM inventory i
        	WHERE equip_id = i.inventory_id;
	
    SELECT i.item_id INTO item
		FROM inventory i
        	WHERE equip_id = i.inventory_id;
	
    DELETE FROM inventory WHERE inventory_id = equip_id;
    
    INSERT INTO equipped (character_id, item_id) VALUES (char_id, item);
END ;;

CREATE PROCEDURE unequip(unequip_id INT UNSIGNED)
BEGIN
    DECLARE char_id INT UNSIGNED;
    DECLARE item INT UNSIGNED;
    
    SELECT e.character_id INTO char_id
		FROM equipped e
        	WHERE unequip_id = e.equipped_id;
	
    SELECT e.item_id INTO item
		FROM equipped e
        	WHERE unequip_id = e.equipped_id;
	
    DELETE FROM equipped WHERE equipped_id = unequip_id;
    
    INSERT INTO inventory (character_id, item_id) VALUES (char_id, item);
END ;;
	
DELIMITER ;
