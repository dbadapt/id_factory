-- shared id_factory that supports Galera clusters
-- id_factory table
CREATE TABLE `id_factory` (
  id BIGINT UNSIGNED NOT NULL,
  namespace CHAR(255) NOT NULL,
  node TINYINT UNSIGNED NOT NULL,
  node_bits TINYINT NOT NULL,
  PRIMARY KEY (id, namespace, node)
) ENGINE=InnoDB;
SET @id_factory_last_nzero=0;
-- id_factory function
delimiter //
CREATE FUNCTION id_factory_next(pnamespace CHAR(32)) RETURNS BIGINT(20) UNSIGNED
BEGIN
  DECLARE retval BIGINT UNSIGNED; -- return value
  DECLARE lock_result INT UNSIGNED; -- get_lock result
  DECLARE last_id BIGINT UNSIGNED; -- last_id assigned
  DECLARE nbits TINYINT UNSIGNED; -- stored node bits
  DECLARE nzero TINYINT UNSIGNED; -- zero based node
  SET retval = 0;
  SET nzero = @@auto_increment_offset - 1;
  -- use 'default' as namespace if none specified
  IF LENGTH(pnamespace) = 0 THEN
    SET pnamespace='default';
  END IF;
  -- lock id_factory for this node only
  IF get_lock(concat('_id_factory_lock',nzero),60) THEN
    -- check and create our record the first time
    IF NOT @id_factory_last_nzero <=> nzero THEN
      SELECT COUNT(*) FROM `id_factory`
      WHERE `namespace`=pnamespace
      AND node=nzero
      INTO last_id;
      -- insert a record if we do not have one
      IF last_id = 0 THEN
        INSERT INTO `id_factory`
          (id,namespace,node,node_bits)
        VALUES
          (0,pnamespace,nzero,2);
      END IF;
    END IF;
    -- select node bits from table
    SELECT node_bits
    FROM `id_factory`
    WHERE `namespace`=pnamespace
    AND node=nzero
    INTO nbits;
    -- increment the id value
    UPDATE `id_factory`
    SET id=last_insert_id(id+1)
    WHERE `namespace`=pnamespace
    AND node=nzero;
    -- unlock
    SET lock_result=release_lock(concat('_id_factory_lock',nzero));
    -- return id with node bits
    SET retval = last_insert_id() << nbits | nzero;
    SET @id_factory_last_nzero = retval;
  END IF;
  RETURN retval;
END
//
delimiter ;
