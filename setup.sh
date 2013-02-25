#!/bin/bash

./build.sh
if [ $? -ne 0 ]; then
    echo "Failed to build"
    exit -1
fi

./install_gems.sh
if [ $? -ne 0 ]; then
    echo "Failed to install gems"
    exit -1
fi

exit 0
