id_factory.sql:  id_factory.cpp.sql
	cpp -E -P -C -nostdinc id_factory.cpp.sql -o id_factory.sql

test_install: id_factory.sql
	mysql -uroot test -e 'drop table if exists id_factory'
	mysql -uroot test -e 'drop function if exists id_factory_next'
	mysql -uroot test < id_factory.sql

test_basic: test_install
	mysql -uroot test -e "select id_factory_next('')"
	mysql -uroot test -e "select id_factory_next('')"
	mysql -uroot test -e "select id_factory_next('')"

