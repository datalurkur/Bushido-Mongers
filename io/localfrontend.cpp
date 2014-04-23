#include "io/localfrontend.h"
#include "io/serverbase.h"

#include "curseme/renderer.h"
#include "world/clientworld.h"
#include "world/clientarea.h"

LocalFrontEnd::LocalFrontEnd(ServerBase* server, const string& name): _server(server), _name(name) {}
LocalFrontEnd::~LocalFrontEnd() {}

bool LocalFrontEnd::connectSender() {
  return _server->assignClient(this, _name);
}

void LocalFrontEnd::disconnectSender() {
  _server->removeClient(this);
}

void LocalFrontEnd::sendToServer(GameEvent* event) {
  _server->clientEvent(this, event);
}

void LocalFrontEnd::draw_map() {
	ClientArea* area = _world->getCurrentArea();

	if(!area) {
	  Debug("Area is not yet defined; waiting");
	  while(!area) {
      area = _world->getCurrentArea();
    }
	}
	IVec2 areaSize = area->getSize();

	int maxX, maxY;
	// TODO - use subwindow instead of stdscr
  getmaxyx(stdscr, maxY, maxX);

  AsciiRenderer renderer(0, 0, maxX, maxY);

  ostringstream areaData;
  for(int j = 0; j < areaSize.y; j++) {
    for(int i = 0; i < areaSize.x; i++) {
      Debug("Getting tile at [" << j << ", " << i << "]");
      auto tile = area->getTile(IVec2(i, j));
      if(tile) {
        switch(tile->getType()) {
        case TileType::Wall:
          areaData << "X";
          break;
        case TileType::Ground:
          areaData << ".";
          break;
        default:
          areaData << "?";
          break;
        }
      }
      else { // (!tile)
        areaData << " ";
      }
    }
  }

  wrefresh(stdscr);
  renderer.setInputData(areaData.str().c_str(), areaSize.x, areaSize.y);
  renderer.render();
}