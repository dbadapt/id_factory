#!/bin/bash

MYSQLOPTS="-uroot -ppassword test"
TABLE="test"
NAMESPACE="test_space"
COUNT=1000
THREADS=10

run_trial() {
  TRIAL=$(echo $RANDOM$RANDOM$RANDOM | sed 's/..\(......\).*/\1/')  # Random number generator (6 digits)
  exec > ${TRIAL}.out
  ./generate_data.pl $TABLE $NAMESPACE $COUNT $TRIAL | mysql $MYSQLOPTS
  echo Trial: ${TRIAL}
  echo In: $COUNT
  echo Out: $(mysql ${MYSQLOPTS} -e "SELECT count(*) from ${TABLE} WHERE trial = '${TRIAL}'")
}

for i in $(seq 1 ${COUNT})
do
  run_trial() &
done

