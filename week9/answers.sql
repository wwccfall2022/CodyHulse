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

DELIMITER ;; 

CREATE TRIGGER new_user
	AFTER INSERT ON users
    FOR EACH ROW
BEGIN
	DECLARE not_new_user INT UNSIGNED;
    DECLARE recent_post INT UNSIGNED;
	DECLARE row_not_found TINYINT DEFAULT FALSE;
    DECLARE user_cursor CURSOR FOR
		SELECT u.user_id
			FROM users u
			WHERE u.user_id != NEW.user_id;
            
	DECLARE CONTINUE HANDLER FOR NOT FOUND
		SET row_not_found = TRUE;
    
    -- Creates the user joined posts
	SET @new_content = CONCAT(NEW.first_name, " ", NEW.last_name, " just joined!");
    
	INSERT INTO posts
		(user_id, content)
	VALUES
		(NEW.user_id, @new_content);
        
	SET recent_post = LAST_INSERT_ID();
	
    -- Creates the notification posts
	OPEN user_cursor;
	user_loop : LOOP
	
	FETCH user_cursor INTO not_new_user;
	
	IF row_not_found THEN
		LEAVE user_loop;
	END IF;
	
	INSERT INTO notifications
		(user_id, post_id)
	VALUES
		(not_new_user, recent_post);
		
	END LOOP user_loop;
	CLOSE user_cursor;
END ;;

-- CREATE EVENT end_sessions
-- CREATE PROCEDURE add_post(user_id, content)
 

DELIMITER ; 
