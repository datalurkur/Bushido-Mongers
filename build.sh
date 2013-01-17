#!/bin/bash

pushd lib/noise
rm *.o
ruby extconf.rb
make
popd

# FIXME - This will be called something different on Linux
mv lib/noise/noise.bundle lib/

# FIXME - It would be nice if we didn't have to depend on gems for this
gem install haml
