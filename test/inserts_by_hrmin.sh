#!/bin/bash

# This script uses the R plotting language to plot the number of inserts every
# minute from the test data

MYSQLOPTS="-uroot -ppassword test"

# create time table with hour and minute of each insert
cat << END_OF_TIME | mysql ${MYSQLOPTS} 2> /dev/null
create table if not exists \`time\` (
  id bigint primary key, 
  hrmin char(5), 
  key time_hrmin (hrmin,id)
);

delete from \`time\`;

set @min_test_time=(select min(ts) from test);

insert into \`time\` 
select 
  id,
  time_format(timediff(ts,@min_test_time), '%H:%i') as hrmin
from test;
END_OF_TIME

# dump insert count by hour and minute
mysql ${MYSQLOPTS} -B  \
  -e "SELECT hrmin,count(*) as \`inserts\` FROM time group by hrmin order by hrmin" 2> /dev/null | \
  sed "s/'/\'/;s/\t/\",\"/g;s/^/\"/;s/$/\"/;s/\n//g" > inserts_by_hrmin.csv 

# plot the data
#
R -f inserts_by_hrmin.r > /dev/null 2>&1

echo Plot is in inserts_by_hrmin.pdf
