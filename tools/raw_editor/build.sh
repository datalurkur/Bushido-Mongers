clang++ -W -Wall -Wextra -pedantic -std=c++11 -ggdb -I ../.. *.cpp\
  ../../interface/choice.cpp\
  ../../resource/raw.cpp\
  ../../util/filesystem.cpp\
  ../../util/log.cpp\
  ../../util/packing.cpp\
  ../../interface/console.cpp\
  ../../util/sectioneddata.cpp\
  ../../game/bobjectmanager.cpp\
  ../../game/compositebobject.cpp\
  ../../game/complexbobject.cpp\
  ../../game/atomicbobject.cpp\
  ../../game/bobject.cpp\
  -o ../../edit_raws
