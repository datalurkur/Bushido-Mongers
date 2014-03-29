CC = clang++
CFLAGS = -g -Wall -Wextra --pedantic -std=c++11 -I.
ifeq ($(shell uname -s),Darwin)
	CFLAGS += -stdlib=libc++
endif
LDFLAGS = -lncurses -lmenu

all: tools tests server

tools: raw_editor_ncurses

tests: test treetest worldtest sockettest

server: curseme/menu.o curseme/curseme.o curseme/input.o curseme/window.o curseme/uistack.o curseme/curselog.o\
        util/log.o util/filesystem.o util/packing.o\
        interface/console.o\
        game/bobject.o game/complexbobject.o game/compositebobject.o game/atomicbobject.o game/bobjectcontainer.o game/bobjectmanager.o game/core.o\
        resource/raw.o\
        server.o

raw_editor: curseme/menu.o curseme/curseme.o curseme/input.o util/log.o tools/raw_editor/main.o resource/raw.o game/bobject.o game/complexbobject.o game/atomicbobject.o game/compositebobject.o util/filesystem.o tools/raw_editor/common.o tools/raw_editor/complex.o tools/raw_editor/composite.o interface/choice.o interface/console.o util/packing.o game/bobjectmanager.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

raw_editor_ncurses: curseme/curseme.o curseme/curselog.o curseme/uistack.o curseme/window.o curseme/menu.o curseme/input.o util/log.o tools/raw_editor_ncurses/main.o resource/raw.o game/bobject.o game/complexbobject.o game/atomicbobject.o game/compositebobject.o util/filesystem.o tools/raw_editor_ncurses/common.o tools/raw_editor_ncurses/complex.o tools/raw_editor_ncurses/composite.o interface/choice.o interface/console.o util/packing.o game/bobjectmanager.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

test: curseme/curseme.o curseme/curselog.o tests/test.o util/log.o game/bobject.o game/bobjectmanager.o game/atomicbobject.o game/complexbobject.o util/sectioneddata.o util/packing.o resource/raw.o util/filesystem.o game/compositebobject.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

treetest: tests/treetest.o util/log.o curseme/curseme.o curseme/curselog.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

worldtest: tests/world_test.o util/log.o curseme/curselog.o world/generator.o world/world.o world/area.o util/timer.o util/filesystem.o util/geom.o world/tile.o world/area.o curseme/renderer.o curseme/curseme.o util/noise.o game/bobjectcontainer.o curseme/window.o curseme/uistack.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

sockettest: tests/socket_test.o util/log.o net/netaddress.o net/socket.o net/tcpsocket.o net/listensocket.o net/serverprovider.o net/tcpbuffer.o net/connectionbuffer.o net/multiconnectionprovider.o net/clientprovider.o net/packet.o util/timestamp.o curseme/curseme.o curseme/curselog.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

%.o : %.cpp %.hpp
	$(CC) $(CFLAGS) $< -c -o $@
%.o : %.cpp %.h
	$(CC) $(CFLAGS) $< -c -o $@
%.o : %.cpp
	$(CC) $(CFLAGS) $^ -c -o $@

clean:
	rm -f server sockettest raw_editor_ncurses test treetest worldtest io/*.o net/*.o util/*.o world/*.o tests/*.o resource/*.o curseme/*.o tools/raw_editor_ncurses/*.o game/*.o interface/*.o *.o
