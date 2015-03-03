#!/bin/bash

MYSQLOPTS="-uroot test"
TABLE="test"
NAMESPACE="test_space"
COUNT=10000
TRIAL=$(echo $RANDOM$RANDOM$RANDOM | sed 's/..\(......\).*/\1/')  # Random number generator (6 digits)

./generate_data.pl $TABLE $NAMESPACE $COUNT $TRIAL | mysql $MYSQLOPTS
echo Trial: ${TRIAL}
echo In: $COUNT
echo Out: $(mysql ${MYSQLOPTS} -e "SELECT count(*) from ${TABLE} WHERE trial = '${TRIAL}'")
