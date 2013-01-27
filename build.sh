#!/bin/bash

platform=$(uname)

pushd lib/noise
echo "Cleaning build"
rm *.o > /dev/null 2>&1
echo "Configuring Ruby extensions"
ruby extconf.rb > /dev/null
echo "Building Ruby extensions"
make > /dev/null
popd

if   [[ "$platform" == 'Linux' ]]; then
	mv lib/noise/noise.so lib/
elif [[ "$platform" == 'FreeBSD' ]]; then
	mv lib/noise/noise.bundle lib/
else
	echo "Unsupported platform $platform"
	exit -1
fi

# TODO - Deal with dependencies here
# openssl
# zlib

echo "Installing gems"
# FIXME - It would be nice if we didn't have to depend on gems for this
gem install haml

exit 0
