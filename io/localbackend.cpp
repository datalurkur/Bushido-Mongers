#include "io/localbackend.h"
#include "io/gameevent.h"
#include "world/clientarea.h"
#include "curseme/renderer.h"

LocalBackEnd::LocalBackEnd(): _mapSource(0) {
  wrefresh(stdscr);

  int w, h;
  getmaxyx(stdscr, h, w);

  int mapHeight;
  if(h > 20) {
    mapHeight = h - 10;
    _logWindow = newwin(10, w, h - 10, 0);
    box(_logWindow, 0, 0);
    wrefresh(_logWindow);
    _logPanel = new CursesLogWindow(_logWindow);
  } else {
    mapHeight = h;
    _logWindow = 0;
    _logPanel = 0;
  }

  _mapWindow = newwin(mapHeight, w, 0, 0);
  wrefresh(_mapWindow);
  _mapPanel = new RenderTarget(_mapWindow);

  _world = new ClientWorld();
}

LocalBackEnd::~LocalBackEnd() {
  delete _mapPanel;
  delwin(_mapWindow);

  if(_logPanel) { delete _logPanel; }
  if(_logWindow) { delwin(_logWindow); }

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
      updateMap((TileDataEvent*)event);
      break;
    case CharacterReady:
      Debug("Character is ready");
      changeArea();
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

  updateMap(0);
}

void LocalBackEnd::updateMap(TileDataEvent *event) {
  ClientArea* currentArea = _world->getCurrentArea();

  #pragma message "Fix this so it displays something intelligent and useful"
  if(!currentArea) { return; }

  IVec2 mapDimensions = _mapSource->getDimensions();

  if(!event) {
    // No tile data update, just regenerate the whole area
    IVec2 areaSize = currentArea->getSize();
    #pragma message "Use a subwindow instead of stdscr"
    for(int j = 0; j < areaSize.y; j++) {
      for(int i = 0; i < areaSize.x; i++) {
        auto tile = currentArea->getTile(IVec2(i, j));
        if(tile) {
          char tileCharacter = getTileRepresentation(tile->getType());
          attr_t tileAttributes = currentArea->isTileShrouded(IVec2(i, j)) ? A_NORMAL : A_BOLD;
          _mapSource->setData(i, j, tileCharacter, tileAttributes);
        }
      }
    }
  } else {
    // We got tile data from the server, update only the updated tiles
    for(auto tileData : event->updated) {
      char tileCharacter = getTileRepresentation(tileData.second.type);
      _mapSource->setData(tileData.first.x, tileData.first.y, tileCharacter, A_BOLD);
    }
    for(auto shroudedTile : event->shrouded) {
      _mapSource->setAttributes(shroudedTile.x, shroudedTile.y, A_NORMAL);
    }
    for(auto visibleTile : event->visible) {
      _mapSource->setAttributes(visibleTile.x, visibleTile.y, A_BOLD);
    }
  }
  RenderTarget target(stdscr, _mapSource);
  target.render();
}

char LocalBackEnd::getTileRepresentation(TileType type) {
  switch(type) {
    case TileType::Wall: return 'X';
    case TileType::Ground: return '.';
    default: return '?';
  }
}
