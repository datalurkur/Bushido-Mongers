#include "io/localbackend.h"
#include "io/gameevent.h"
#include "world/clientarea.h"
#include "curseme/renderer.h"

LocalBackEnd::LocalBackEnd(): _mapSource(0) {
  wrefresh(stdscr);
  _world = new ClientWorld();
}
LocalBackEnd::~LocalBackEnd() {
  delete _world;
}

void LocalBackEnd::sendToClient(GameEvent* event) {
  EventQueue results;
  switch(event->type) {
    case AreaData:
      _world->processWorldEvent(event, results);
      changeArea();
      break;
    case TileData:
      _world->processWorldEvent(event, results);
      updateMap();
      break;
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

  for(auto result : results) {
    sendToServer(result.get());
  }
}

void LocalBackEnd::changeArea() {
  ClientArea* currentArea = _world->getCurrentArea();

  #pragma message "Fix this so it displays something intelligent and useful"
  if(!currentArea) { return; }

  if(_mapSource) { delete _mapSource; }
  _mapSource = new RenderSource(currentArea->getSize());

  updateMap();
}

void LocalBackEnd::updateMap() {
  ClientArea* currentArea = _world->getCurrentArea();

  #pragma message "Fix this so it displays something intelligent and useful"
  if(!currentArea) { return; }

  IVec2 areaSize = currentArea->getSize();
  #pragma message "Use a subwindow instead of stdscr"
  for(int j = 0; j < areaSize.y; j++) {
    for(int i = 0; i < areaSize.x; i++) {
      auto tile = currentArea->getTile(IVec2(i, j));
      if(tile) {
        switch(tile->getType()) {
        case TileType::Wall:
          _mapSource->setData(i, j, 'X', A_NORMAL);
          break;
        case TileType::Ground:
          _mapSource->setData(i, j, '.', A_NORMAL);
          break;
        default:
          _mapSource->setData(i, j, '?', A_NORMAL);
          break;
        }
      }
    }
  }
  RenderTarget target(stdscr, _mapSource);
  target.render();
}
