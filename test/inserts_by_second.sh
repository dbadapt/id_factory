#!/bin/bash

# This script uses the R plotting language to plot the number of inserts every
# minute from the test data

MYSQLOPTS="-uroot -ppassword test"

# create time table with hour and minute of each insert
cat << END_OF_TIME | mysql ${MYSQLOPTS} 2> /dev/null
drop table if exists \`time\`;

create table if not exists \`time\` (
  id bigint primary key, 
  timeinc bigint,
  key time_timeinc (timeinc,id)
);

set @min_test_time=(select min(ts) from test);

insert into \`time\` 
select 
  id,
  time_to_sec(timediff(ts,@min_test_time)) as timeinc
from test;
END_OF_TIME

# dump insert count by hour and minute
mysql ${MYSQLOPTS} -B  \
  -e "SELECT timeinc,count(*) as \`inserts\` FROM time group by timeinc order by timeinc" 2> /dev/null | \
  sed "s/'/\'/;s/\t/\",\"/g;s/^/\"/;s/$/\"/;s/\n//g" > inserts_by_time.csv 

# plot the data
#
R -f inserts_by_time.r > /dev/null 2>&1

echo Plot is in inserts_by_time.pdf
