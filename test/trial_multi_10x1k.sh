#!/bin/bash

# This trial uses the standard mysql client to test simultaneous threads
# generating id's using the id_factory_next() function.  Running this test on
# a wsrep cluster will probably result in some errors as the mysql client will
# not automatically retry on deadlock and lock wait errors.

MYSQLOPTS="-uroot -ppassword -f -w test"
TABLE="test"
NAMESPACE="test_space"
COUNT=1024
THREADS=16

HAS_GALERA=$(mysql ${MYSQLOPTS} -e "show variables like 'wsrep%commit'" 2>/dev/null | grep -c 'commit')
if [ "$HAS_GALERA" == "1" ]; then
  GALERA="galera"
fi

run_trial() {
  TRIAL=$(echo $RANDOM$RANDOM$RANDOM | sed 's/..\(........\).*/\1/')  # Random number generator (8 digits)
  LOG="trial_out/${TRIAL}.out"
  ./generate_data.pl $TABLE $NAMESPACE $COUNT $TRIAL ${GALERA:-} | mysql $MYSQLOPTS 2>&1 > ${LOG} 2>&1 
  echo Trial: ${TRIAL} >> ${LOG}
  echo In: $COUNT >> ${LOG}
  echo Out: $(mysql ${MYSQLOPTS} -e "SELECT count(*) from ${TABLE} WHERE trial = '${TRIAL}'" 2> /dev/null) 2>&1 >> ${LOG} 2>&1
  exit 0
}

cd `dirname $0`

mkdir -p trial_out

for i in $(seq 1 ${THREADS})
do
  run_trial &
done
