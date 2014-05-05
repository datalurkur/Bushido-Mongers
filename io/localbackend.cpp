#include "io/localbackend.h"
#include "io/gameevent.h"
#include "world/clientarea.h"
#include "curseme/renderer.h"

LocalBackEnd::LocalBackEnd(): _consumerShouldDie(false), _eventsReady(false), _mapSource(0) {
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

  _eventConsumer = thread(&LocalBackEnd::consumeEvents, this);
}

LocalBackEnd::~LocalBackEnd() {
  // Tell the event consumer that it should die and wait for it to do so
  if(_eventConsumer.joinable()) {
    _consumerShouldDie = true;
    _eventsReadyCondition.notify_all();
    _eventConsumer.join();
  }

  // Tear down the UI
  delete _mapPanel;
  delwin(_mapWindow);

  if(_logPanel) { delete _logPanel; }
  if(_logWindow) { delwin(_logWindow); }
}

void LocalBackEnd::sendToClient(SharedGameEvent event) {
  unique_lock<mutex> lock(_eventLock);
  _events.pushEvent(event);
  _eventsReady = true;
  _eventsReadyCondition.notify_all();
}

void LocalBackEnd::sendToClient(EventQueue&& queue) {
  unique_lock<mutex> lock(_eventLock);
  _events.appendEvents(move(queue));
  _eventsReady = true;
  _eventsReadyCondition.notify_all();
}

void LocalBackEnd::consumeEvents() {
  while(!_consumerShouldDie) {
    unique_lock<mutex> lock(_eventLock);
    while(!_eventsReady && !_consumerShouldDie) _eventsReadyCondition.wait(lock);

    if(_events.empty()) { continue; }
    SharedGameEvent event = _events.popEvent();
    if(_events.empty()) {
      _eventsReady = false;
    }
    lock.unlock();
    consumeSingleEvent(event.get());
  }
}

void LocalBackEnd::consumeSingleEvent(GameEvent* event) {
  EventQueue results;
  switch(event->type) {
    case AreaData:
      _world.processWorldEvent(event, results);
      changeArea();
      break;
    case TileData:
      _world.processWorldEvent(event, results);
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
  ClientArea* currentArea = _world.getCurrentArea();

  #pragma message "Fix this so it displays something intelligent and useful"
  if(!currentArea) { return; }

  if(_mapSource) { delete _mapSource; }
  _mapSource = new RenderSource(currentArea->getSize());
  _mapPanel->setRenderSource(_mapSource);

  updateMap(0);
}

void LocalBackEnd::updateMap(TileDataEvent *event) {
  ClientArea* currentArea = _world.getCurrentArea();

  #pragma message "Fix this so it displays something intelligent and useful"
  if(!currentArea) { return; }

  IVec2 mapDimensions = _mapSource->getDimensions();

  if(!event) {
    // No tile data update, just regenerate the whole area
    IVec2 areaSize = currentArea->getSize();
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
  _mapPanel->render();
}

char LocalBackEnd::getTileRepresentation(TileType type) {
  switch(type) {
    case TileType::Wall: return 'X';
    case TileType::Ground: return '.';
    default: return '?';
  }
}
