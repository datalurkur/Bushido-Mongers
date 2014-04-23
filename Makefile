CC = clang++
CFLAGS = -g -Wall -Wextra --pedantic -std=c++11 -I.
ifeq ($(shell uname -s),Darwin)
	CFLAGS += -stdlib=libc++
endif
LDFLAGS = -lncurses -lmenu -lpthread

all: tools tests server

tools: raw_editor_ncurses

tests: treetest worldtest sockettest geomtest

server: curseme/menu.o curseme/curseme.o curseme/input.o curseme/renderer.o curseme/window.o curseme/curselog.o util/log.o util/filesystem.o util/packing.o util/timer.o util/noise.o util/geom.o interface/console.o game/bobject.o game/complexbobject.o game/compositebobject.o game/atomicbobject.o game/bobjectcontainer.o game/bobjectmanager.o game/core.o resource/raw.o world/generator.o world/world.o world/area.o world/tile.o server.o io/localgameclient.o io/clientbase.o io/gameserver.o io/serverbase.o io/localfrontend.o io/localbackend.o io/eventqueue.o game/observable.o util/timestamp.o world/worldbase.o world/clientworld.o world/areabase.o world/clientarea.o world/tilebase.o world/clienttile.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

raw_editor: curseme/menu.o curseme/curseme.o curseme/input.o util/log.o tools/raw_editor/main.o resource/raw.o game/bobject.o game/complexbobject.o game/atomicbobject.o game/compositebobject.o util/filesystem.o tools/raw_editor/common.o tools/raw_editor/complex.o tools/raw_editor/composite.o interface/choice.o interface/console.o util/packing.o game/bobjectmanager.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

raw_editor_ncurses: curseme/curseme.o curseme/curselog.o curseme/window.o curseme/menu.o curseme/input.o util/log.o tools/raw_editor_ncurses/main.o resource/raw.o game/bobject.o game/complexbobject.o game/atomicbobject.o game/compositebobject.o util/filesystem.o tools/raw_editor_ncurses/common.o tools/raw_editor_ncurses/complex.o tools/raw_editor_ncurses/composite.o interface/choice.o interface/console.o util/packing.o game/bobjectmanager.o game/bobjectcontainer.o game/observable.o util/timestamp.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

treetest: tests/treetest.o util/log.o curseme/curseme.o curseme/curselog.o curseme/window.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

geomtest: tests/geom_test.o util/log.o curseme/curselog.o util/geom.o util/filesystem.o curseme/window.o curseme/renderer.o curseme/curseme.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

worldtest: tests/world_test.o util/log.o curseme/curselog.o world/generator.o world/world.o world/area.o util/timer.o util/filesystem.o util/geom.o world/tile.o world/area.o curseme/renderer.o curseme/curseme.o util/noise.o game/bobjectcontainer.o curseme/window.o world/areabase.o world/tilebase.o world/worldbase.o world/clienttile.o world/clientarea.o world/clientworld.o game/observable.o util/timestamp.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

sockettest: tests/socket_test.o util/log.o net/netaddress.o net/socket.o net/tcpsocket.o net/listensocket.o net/serverprovider.o net/tcpbuffer.o net/connectionbuffer.o net/multiconnectionprovider.o net/packet.o util/timestamp.o curseme/curseme.o curseme/curselog.o curseme/window.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

%.o : %.cpp %.hpp
	$(CC) $(CFLAGS) $< -c -o $@
%.o : %.cpp %.h
	$(CC) $(CFLAGS) $< -c -o $@
%.o : %.cpp
	$(CC) $(CFLAGS) $^ -c -o $@

clean:
	rm -f geomtest server sockettest raw_editor_ncurses test treetest worldtest io/*.o net/*.o util/*.o world/*.o tests/*.o resource/*.o curseme/*.o tools/raw_editor_ncurses/*.o game/*.o interface/*.o *.o
