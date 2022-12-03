CREATE SCHEMA social;
USE social;

CREATE TABLE users (
	user_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
	first_name VARCHAR(30) NOT NULL,
	last_name VARCHAR(30) NOT NULL,
	email VARCHAR(50) NOT NULL,
	created_on TIMESTAMP NOT NULL DEFAULT NOW()
 );

CREATE TABLE sessions (
    session_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NOT NULL,
    created_on TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_on TIMESTAMP NOT NULL DEFAULT NOW() ON UPDATE NOW(),
    CONSTRAINT sessions_fk_users
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE friends (
	user_friend_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NOT NULL,
    friend_id INT UNSIGNED NOT NULL,
    CONSTRAINT friends_fk_users
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
	CONSTRAINT friends_fk_users2
        FOREIGN KEY (friend_id)
        REFERENCES users (user_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE posts (
	post_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NOT NULL,
    created_on TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_on TIMESTAMP NOT NULL DEFAULT NOW() ON UPDATE NOW(),
    content VARCHAR(50) NOT NULL,
    CONSTRAINT posts_fk_users
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE notifications (
	notification_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NOT NULL,
    post_id INT UNSIGNED NOT NULL,
    CONSTRAINT notifications_fk_users
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
	CONSTRAINT notifications_fk_posts
        FOREIGN KEY (post_id)
        REFERENCES posts (post_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE OR REPLACE VIEW notification_posts AS
	SELECT n.user_id, u.first_name, u.last_name, p.post_id, p.content
		FROM users u
		LEFT OUTER JOIN posts p
			ON u.user_id = p.user_id
		LEFT OUTER JOIN notifications n
			ON p.user_id = n.user_id;

DELIMITER ;; 

CREATE TRIGGER new_user
	AFTER INSERT ON users
    FOR EACH ROW
	BEGIN
		DECLARE new_user_id INT UNSIGNED;
		DECLARE content VARCHAR(70);
        DECLARE new_first_name VARCHAR(30);
        DECLARE new_last_name VARCHAR(30);
        /*
		DECLARE row_not_found TINYINT DEFAULT FALSE;
        
		DECLARE user_cursor CURSOR FOR
        SELECT user_id, first_name, last_name
			FROM users 
			WHERE user_id = NEW.user_id;
		DECLARE CONTINUE HANDLER FOR NOT FOUND
			SET row_not_found = TRUE;
		
        
        OPEN user_cursor;
		user_loop : LOOP
        
        FETCH user_cursor INTO new_user_id, new_first_name, new_last_name;
		
		IF row_not_found THEN
			LEAVE user_loop;
		END IF;
        */
        
        SELECT NEW.user_id INTO new_user_id;
        SELECT NEW.first_name INTO new_first_name;
        SELECT NEW.last_name INTO new_last_name;
        
		INSERT INTO posts
			(user_id, content)
		VALUES
			(new_user_id, new_first_name + " " + new_last_name + " just joined!");
		/*
		END LOOP user_loop;
		CLOSE user_cursor;
        */
	END ;;
-- CREATE PROCEDURE add_post(user_id, content)
-- 	INSERT INTO posts p (p.user_id, p.content) VALUES (user_id, content);

DELIMITER ; 
