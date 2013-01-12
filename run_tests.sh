#!/bin/bash

rm fail.log
for file in $( find . | grep /.*/test/.*\.rb$ ); do
    ruby $file > /dev/null 2>>fail.log
    if [ $? -ne 0 ]; then
        echo -e "\033[1;31mTest failed\033[0m : $file"
    else
        echo -e "Test passed : $file"
    fi
done
