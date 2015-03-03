#!/usr/bin/perl -w
use strict;

if ($#ARGV != 3) {
  print "Usage: $0 {table} {namespace} {count} {trial}\n";
  exit;
}

my $table=$ARGV[0];
my $namespace=$ARGV[1];
my $count=$ARGV[2];
my $trial=$ARGV[3];

print<<END_CREATE;
CREATE TABLE IF NOT EXISTS $table (
  id BIGINT(20) UNSIGNED PRIMARY KEY,
  namespace CHAR(255),
  trial CHAR(255),
  count BIGINT(20),
  total BIGINT(20),
  ts TIMESTAMP NULL DEFAULT '0000-00-00 00:00:00',
  KEY ${table}_trial (trial,id)
);

END_CREATE

for (my $i=1; $i <= $count; $i++) {
  print<<END_INSERT;
INSERT INTO $table (id,namespace,trial,count,total,ts) VALUES (id_factory_next('$namespace'),'$namespace','$trial',$i,$count,now());
END_INSERT
}
