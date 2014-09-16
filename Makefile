CC = clang++
CFLAGS = -g -Wall -Wextra --pedantic -std=c++11 -I.
ifeq ($(shell uname -s),Darwin)
	CFLAGS += -stdlib=libc++
endif
LDFLAGS = -lncurses -lmenu -lpthread

BASIC_UTIL_OBJS = util/timestamp.o util/log.o util/filesystem.o
CURSES_OBJS = curseme/curseme.o curseme/curselog.o curseme/window.o curseme/renderer.o
RESOURCE_OBJS = resource/raw.o resource/protobobject.o resource/protoatomic.o resource/protocomposite.o resource/protocomplex.o resource/protocontainer.o resource/protoextension.o

all: tools tests server client

tools: raw_editor

tests: treetest worldtest geomtest

genproto: protocol/rcparser.o util/stringhelper.o protocol/codegenerator.o protocol/protocol_generator.o $(BASIC_UTIL_OBJS)
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

server: game/bobjecttypes.o game/bobjectextension.o io/gameevent.o io/eventmeta.o curseme/menudriver.o curseme/cursesmenudriver.o curseme/renderer.o util/timer.o util/noise.o util/geom.o game/bobject.o game/complexbobject.o game/compositebobject.o game/atomicbobject.o game/containerbase.o game/containerbobject.o game/bobjectmanager.o game/core.o world/generator.o world/world.o world/area.o world/tile.o server.o ui/state.o state/gamestate.o state/inspectstate.o io/localgameclient.o io/clientbase.o io/gameserver.o io/serverbase.o io/localfrontend.o io/localbackend.o io/eventqueue.o game/observable.o world/worldbase.o world/clientworld.o world/areabase.o world/clientarea.o world/tilebase.o world/clienttile.o util/uniquestringpair.o ui/menu.o ui/titlebox.o ui/prompt.o curseme/hotkeymenudriver.o util/serialize.o game/combat.o game/objectobserver.o net/listensocket.o io/remoteclientstub.o io/remotebackend.o net/tcpsocket.o net/netaddress.o net/socket.o net/tcpbuffer.o util/stringhelper.o util/streambuffering.o world/descriptor.o $(CURSES_OBJS) $(RESOURCE_OBJS) $(BASIC_UTIL_OBJS) resource/visualization.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

client: game/bobjecttypes.o io/gameevent.o io/eventmeta.o curseme/menudriver.o curseme/cursesmenudriver.o curseme/renderer.o curseme/hotkeymenudriver.o ui/menu.o util/log.o client.o io/remotegameclient.o io/localbackend.o io/remotefrontend.o world/clientworld.o world/worldbase.o io/clientbase.o io/eventqueue.o world/clientarea.o world/areabase.o net/tcpbuffer.o net/netaddress.o ui/prompt.o ui/state.o ui/titlebox.o state/gamestate.o state/inspectstate.o net/tcpsocket.o net/socket.o game/containerbase.o world/tilebase.o game/observable.o world/clienttile.o util/stringhelper.o util/streambuffering.o $(CURSES_OBJS) $(RESOURCE_OBJS) $(BASIC_UTIL_OBJS) resource/visualization.o
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

raw_editor: util/streambuffering.o game/bobjecttypes.o tools/raw_editor_ncurses/main.o resource/raw.o resource/protobobject.o game/bobject.o game/complexbobject.o game/atomicbobject.o game/compositebobject.o tools/raw_editor_ncurses/common.o tools/raw_editor_ncurses/complex.o tools/raw_editor_ncurses/composite.o game/bobjectmanager.o game/containerbase.o game/containerbobject.o game/observable.o util/uniquestringpair.o ui/menu.o curseme/menudriver.o ui/titlebox.o ui/prompt.o curseme/cursesmenudriver.o curseme/hotkeymenudriver.o util/serialize.o game/combat.o $(CURSES_OBJS) $(RESOURCE_OBJS) $(BASIC_UTIL_OBJS)
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

treetest: tests/treetest.o $(CURSES_OBJS) $(BASIC_UTIL_OBJS)
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

geomtest: tests/geom_test.o util/geom.o curseme/renderer.o $(CURSES_OBJS) $(BASIC_UTIL_OBJS)
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

worldtest: io/gameevent.o resource/raw.o util/streambuffering.o game/bobjecttypes.o tests/world_test.o world/generator.o world/world.o world/area.o util/timer.o util/geom.o world/tile.o world/area.o curseme/renderer.o util/noise.o game/containerbase.o game/containerbobject.o world/areabase.o world/descriptor.o world/tilebase.o world/worldbase.o world/clienttile.o world/clientarea.o world/clientworld.o game/observable.o util/uniquestringpair.o game/combat.o game/bobjectmanager.o game/complexbobject.o game/bobject.o game/atomicbobject.o game/compositebobject.o io/eventmeta.o $(CURSES_OBJS) $(RESOURCE_OBJS) $(BASIC_UTIL_OBJS)
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

%.o : %.cpp %.hpp
	$(CC) $(CFLAGS) $< -c -o $@
%.o : %.cpp %.h
	$(CC) $(CFLAGS) $< -c -o $@
%.o : %.cpp
	$(CC) $(CFLAGS) $^ -c -o $@
%.cpp : %.rc genproto
	./genproto $<

clean:
	rm -f genproto geomtest client server raw_editor test treetest worldtest io/*.o net/*.o util/*.o world/*.o tests/*.o resource/*.o curseme/*.o tools/raw_editor_ncurses/*.o game/*.o ui/*.o *.o protocol/*.o io/gameevent.h io/gameevent.cpp state/*.o

.SECONDARY:
