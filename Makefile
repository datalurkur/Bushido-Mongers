CC = clang++
CFLAGS = -g -Wall -Wextra --pedantic -std=c++11 -I.
ifeq ($(shell uname -s),Darwin)
	CFLAGS += -stdlib=libc++
endif
LDFLAGS = -lncurses -lmenu -lpthread

BOB_RESOURCES = resource/protobobject.o resource/protoatomic.o resource/protocomposite.o resource/protocomplex.o resource/protocontainer.o resource/protoextension.o

all: tools tests server

tools: raw_editor_ncurses

tests: treetest worldtest sockettest geomtest

genproto: protocol/rcparser.o util/stringhelper.o util/filesystem.o protocol/codegenerator.o protocol/protocol_generator.o util/log.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

server: io/gameevent.o io/eventmeta.o curseme/curseme.o curseme/menudriver.o curseme/cursesmenudriver.o curseme/renderer.o curseme/window.o curseme/curselog.o util/log.o util/filesystem.o util/packing.o util/timer.o util/noise.o util/geom.o game/bobject.o game/complexbobject.o game/compositebobject.o game/atomicbobject.o game/containerbase.o game/containerbobject.o game/bobjectmanager.o game/core.o resource/raw.o world/generator.o world/world.o world/area.o world/tile.o server.o io/localgameclient.o io/clientbase.o io/gameserver.o io/serverbase.o io/localfrontend.o io/localbackend.o io/eventqueue.o game/observable.o util/timestamp.o world/worldbase.o world/clientworld.o world/areabase.o world/clientarea.o world/tilebase.o world/clienttile.o util/uniquestringpair.o util/sectioneddata.o ui/menu.o ui/titlebox.o ui/prompt.o curseme/hotkeymenudriver.o util/serialize.o $(BOB_RESOURCES)
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

raw_editor_ncurses: curseme/curseme.o curseme/curselog.o curseme/window.o util/log.o tools/raw_editor_ncurses/main.o resource/raw.o game/bobject.o game/complexbobject.o game/atomicbobject.o game/compositebobject.o util/filesystem.o tools/raw_editor_ncurses/common.o tools/raw_editor_ncurses/complex.o tools/raw_editor_ncurses/composite.o util/packing.o game/bobjectmanager.o game/containerbase.o game/containerbobject.o game/observable.o util/timestamp.o util/uniquestringpair.o util/sectioneddata.o ui/menu.o curseme/menudriver.o ui/titlebox.o ui/prompt.o curseme/cursesmenudriver.o curseme/hotkeymenudriver.o util/serialize.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

treetest: tests/treetest.o util/log.o curseme/curseme.o curseme/curselog.o curseme/window.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

geomtest: tests/geom_test.o util/log.o curseme/curselog.o util/geom.o util/filesystem.o curseme/window.o curseme/renderer.o curseme/curseme.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

worldtest: io/gameevent.o tests/world_test.o util/log.o curseme/curselog.o world/generator.o world/world.o world/area.o util/timer.o util/filesystem.o util/geom.o world/tile.o world/area.o curseme/renderer.o curseme/curseme.o util/noise.o game/containerbase.o game/containerbobject.o curseme/window.o world/areabase.o world/tilebase.o world/worldbase.o world/clienttile.o world/clientarea.o world/clientworld.o game/observable.o util/timestamp.o util/uniquestringpair.o game/bobjectmanager.o game/complexbobject.o game/bobject.o util/packing.o game/atomicbobject.o game/compositebobject.o resource/raw.o util/sectioneddata.o io/eventmeta.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

sockettest: tests/socket_test.o util/log.o net/netaddress.o net/socket.o net/tcpsocket.o net/listensocket.o net/serverprovider.o net/tcpbuffer.o net/connectionbuffer.o net/multiconnectionprovider.o net/packet.o util/timestamp.o curseme/curseme.o curseme/curselog.o curseme/window.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

%.o : %.cpp %.hpp
	$(CC) $(CFLAGS) $< -c -o $@
%.o : %.cpp %.h
	$(CC) $(CFLAGS) $< -c -o $@
%.o : %.cpp
	$(CC) $(CFLAGS) $^ -c -o $@
%.cpp : %.rc genproto
	./genproto $^

regen:
	rm -f io/gameevent.h io/gameevent.cpp

clean:
	rm -f genproto geomtest server sockettest raw_editor_ncurses test treetest worldtest io/*.o net/*.o util/*.o world/*.o tests/*.o resource/*.o curseme/*.o tools/raw_editor_ncurses/*.o game/*.o ui/*.o *.o protocol/*.o io/gameevent.h io/gameevent.cpp
