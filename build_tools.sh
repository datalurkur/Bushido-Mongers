#!/bin/bash
pushd tools/raw_editor
./build.sh
popd
pushd tools/raw_editor_ncurses
./build.sh
popd
