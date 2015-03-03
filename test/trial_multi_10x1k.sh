#!/bin/bash

MYSQLOPTS="-uroot -ppassword test"
TABLE="test"
NAMESPACE="test_space"
COUNT=2048
THREADS=32

run_trial() {
  TRIAL=$(echo $RANDOM$RANDOM$RANDOM | sed 's/..\(......\).*/\1/')  # Random number generator (6 digits)
  LOG="trial_out/${TRIAL}.out"
  ./generate_data.pl $TABLE $NAMESPACE $COUNT $TRIAL | mysql $MYSQLOPTS 2>&1 > ${LOG} 2>&1 
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

