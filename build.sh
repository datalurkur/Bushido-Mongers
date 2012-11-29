#!/bin/bash

pushd math/lib/noise
ruby extconf.rb
make
popd

# FIXME - This will be called something different on Linux
mv math/lib/noise/noise.bundle math/
