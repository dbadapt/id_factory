-- shared id_factory that supports Galera clusters

#define TABLE_NAME  `id_factory`
#define NODE_BITS   2

-- id_factory table
CREATE TABLE TABLE_NAME (
  id BIGINT UNSIGNED NOT NULL,
  namespace CHAR(255) NOT NULL,
  node TINYINT UNSIGNED NOT NULL,
  node_bits TINYINT NOT NULL,
  PRIMARY KEY (id, namespace, node)
) ENGINE=InnoDB;

SET @id_factory_last_nzero=0;
SET @id_factory_last_id=0;

-- id_factory function
delimiter //
CREATE FUNCTION id_factory_next(pnamespace CHAR(255)) RETURNS BIGINT(20) UNSIGNED
BEGIN
  DECLARE retval BIGINT UNSIGNED;     -- return value
  DECLARE lock_result INT UNSIGNED;   -- get_lock result
  DECLARE last_id BIGINT UNSIGNED;    -- last_id assigned
  DECLARE nbits TINYINT UNSIGNED;     -- stored node bits
  DECLARE nzero TINYINT UNSIGNED;     -- zero based node
  DECLARE bleh CHAR(255);
  SET retval = 0;
  SET nzero = @@auto_increment_offset - 1;
  -- use 'default' as namespace if none specified
  IF LENGTH(pnamespace) = 0 THEN
    SET pnamespace='default';
  END IF;
  -- check and create our record the first time
  IF NOT @id_factory_last_nzero <=> nzero THEN
    SELECT COUNT(*) FROM TABLE_NAME 
    WHERE `namespace`=pnamespace
    AND node=nzero
    INTO last_id;
    -- insert a record if we do not have one
    IF last_id = 0 THEN
      INSERT INTO TABLE_NAME
        (id,namespace,node,node_bits)
      VALUES
        (0,pnamespace,nzero,NODE_BITS); 
    END IF;
  END IF;
  -- select the current id
  SELECT (id+1),node_bits 
  FROM TABLE_NAME
  WHERE `namespace`=pnamespace
  AND node=nzero
  INTO last_id,nbits
  FOR UPDATE;
  -- increment the id value 
  UPDATE TABLE_NAME
  SET id=last_id
  WHERE `namespace`=pnamespace
  AND node=nzero;
  -- compute retval
  SET retval = last_id << nbits | nzero;
  -- record our node and last_id
  SET @id_factory_last_nzero = nzero;
  SET @id_factory_last_id = retval;
  RETURN retval;
END
//
delimiter ;

delimiter //
CREATE FUNCTION id_factory_last() RETURNS BIGINT(20) UNSIGNED
BEGIN
  RETURN @id_factory_last_id;
END
//
delimiter ;

