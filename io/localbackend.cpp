#include "io/localbackend.h"
#include "io/gameevent.h"
#include "world/clientarea.h"
#include "curseme/renderer.h"

LocalBackEnd::LocalBackEnd() {
  _world = new ClientWorld();
}
LocalBackEnd::~LocalBackEnd() {
  delete _world;
}

void LocalBackEnd::sendToClient(GameEvent* event) {
  switch(event->type) {
    case AreaData:
    case TileData: {
      EventQueue results;
      _world->processWorldEvent(event, results);
      for(auto result : results) {
        sendToServer(result.get());
      }
      updateMap();
      break;
    }
    case CharacterReady:
      Debug("Character is ready");
      updateMap();
      break;
    case CharacterNotReady:
      Debug("Character not ready - " << ((CharacterNotReadyEvent*)event)->reason);
      break;
    case CharacterMoved:
      Debug("Character moved");
      break;
    case MoveFailed:
      Debug("Failed to move - " << ((MoveFailedEvent*)event)->reason);
      break;
    default:
      Warn("Unhandled game event type " << event->type);
      break;
  }
}

void LocalBackEnd::updateMap() {
  ClientArea* area = _world->getCurrentArea();

  if(!area) {
    Debug("Area is not yet defined; displaying nothing");
    // TODO - Add code that displays "Awaiting data from server"
    return;
  }

  IVec2 areaSize = area->getSize();

  int maxX, maxY;
  // TODO - use subwindow instead of stdscr
  getmaxyx(stdscr, maxY, maxX);

  // TODO - Move this renderer out of this function and into either the local backend privates or a menu system of some kind
  // It doesn't make sense to create a renderer here for the purpose of displaying something once - that's a lot of memory allocation and deallocation for a single render
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
