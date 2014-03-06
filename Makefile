CC = clang++
CFLAGS = -g -Wall -Wextra --pedantic -std=c++11 -stdlib=libc++ -I.
LDFLAGS = -lncurses -lmenu

SOURCES = menu.cpp curseme.cpp
OBJECTS = $(SOURCES:.cpp=.o)

all: tools tests

tools: raw_editor_ncurses

tests: test treetest worldtest

raw_editor_ncurses: util/*.cpp resource/*.cpp game/*.cpp interface/*.cpp curseme/*.cpp tools/raw_editor_ncurses/*.cpp
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

test: tests/test.cpp util/*.cpp game/*.cpp resource/*.cpp
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

treetest: tests/treetest.cpp util/*.cpp
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

worldtest: tests/world_test.cpp util/*.cpp world/*.cpp
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

clean:
	rm -f raw_editor_ncurses test treetest worldtest
