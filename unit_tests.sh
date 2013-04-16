#!/bin/bash

rm fail.log
for file in $( find . | grep /.*/test/.*\.rb$ ); do
    echo -en "Running $file - "
    start_time=$(date +%s)
    ruby $file > /dev/null 2>>fail.log
    if [ $? -ne 0 ]; then
        echo -en "\033[1;31mTest failed\033[0m "
    else
        echo -en "\033[1;32mTest passed\033[0m "
    fi
    end_time=$(date +%s)
    echo -e "in $(($end_time - $start_time)) seconds"
done
