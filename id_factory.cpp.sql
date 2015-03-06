-- shared id_factory that supports Galera clusters

#define TABLE_NAME  `id_factory`
#define NODE_BITS   2

-- id_factory table
CREATE TABLE TABLE_NAME (
  namespace CHAR(255) NOT NULL,
  node TINYINT UNSIGNED NOT NULL,
  id BIGINT UNSIGNED NOT NULL,
  node_bits TINYINT NOT NULL,
  PRIMARY KEY (namespace, node)
) ENGINE=InnoDB;

-- id_factory function
delimiter //
CREATE FUNCTION id_factory_next(pnamespace CHAR(255)) RETURNS BIGINT(20) UNSIGNED
BEGIN
  DECLARE last_id BIGINT UNSIGNED;    -- last_id assigned
  DECLARE nbits TINYINT UNSIGNED;     -- stored node bits
  DECLARE nzero TINYINT UNSIGNED;     -- zero based node
  SET nzero = @@auto_increment_offset - 1;
  -- use 'default' as namespace if none specified
  IF LENGTH(pnamespace) = 0 THEN
    SET pnamespace='default';
  END IF;
  -- insert or update
  INSERT INTO TABLE_NAME
    (id,namespace,node,node_bits)
  VALUES
    (1,pnamespace,nzero,NODE_BITS)
  ON DUPLICATE KEY UPDATE
    id=(id+1);
  -- select them back
  SELECT id,node_bits
  FROM TABLE_NAME
  WHERE `namespace`=pnamespace
  AND node=nzero
  INTO last_id,nbits;
  RETURN last_id << nbits | nzero;
END
//
delimiter ;

