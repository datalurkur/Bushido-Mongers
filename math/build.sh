#!/bin/bash

pushd lib/noise
ruby extconf.rb
make
popd

# FIXME - This will be called something different on Linux
mv lib/noise/noise.bundle ./
