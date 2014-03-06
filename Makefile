CC = clang++
CFLAGS = -g -Wall -Wextra --pedantic -std=c++11 -I.
ifeq ($(shell uname -s),Darwin)
	CFLAGS += -stdlib=libc++
endif
LDFLAGS = -lncurses -lmenu

SOURCES = menu.cpp curseme.cpp
OBJECTS = $(SOURCES:.cpp=.o)

all: tools tests

tools: raw_editor_ncurses

tests: test treetest worldtest

raw_editor_ncurses: curseme/menu.o curseme/curseme.o util/log.o tools/raw_editor_ncurses/main.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

test: tests/test.o util/log.o game/bobject.o game/bobjectmanager.o game/atomicbobject.o game/complexbobject.o util/sectioneddata.o util/packing.o resource/raw.o util/filesystem.o game/compositebobject.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

treetest: tests/treetest.o util/log.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

worldtest: tests/world_test.o util/log.o world/generator.o world/world.o world/area.o util/timer.o util/filesystem.o util/geom.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

%.o : %.cpp
	$(CC) $(CFLAGS) $^ -c -o $@

clean:
	rm -f raw_editor_ncurses test treetest worldtest util/*.o world/*.o tests/*.o resource/*.o curseme/*.o tools/raw_editor_ncurses/*.o game/*.o interface/*.o
