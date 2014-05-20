#include "io/localbackend.h"
#include "io/gameevent.h"
#include "world/clientarea.h"
#include "curseme/renderer.h"

LocalBackEnd::LocalBackEnd(): _consumerShouldDie(false), _eventsReady(false), _mapSource(0), _characterID(0) {
  wrefresh(stdscr);

  int w, h;
  getmaxyx(stdscr, h, w);

  int mapHeight;
  int desiredLogHeight = 5;
  if(h > 4 * desiredLogHeight) {
    mapHeight = h - desiredLogHeight;
    _logWindow = newwin(desiredLogHeight, w, h - desiredLogHeight, 0);
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
      _characterID = ((CharacterReadyEvent*)event)->ID;
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
        updateTileRepresentation(IVec2(i, j), currentArea);
      }
    }
  } else {
    // We got tile data from the server, update only the updated tiles
    for(auto tileData : event->updated) {
      updateTileRepresentation(tileData.first, currentArea);
    }
    for(auto shroudedTile : event->shrouded) {
      updateTileRepresentation(shroudedTile, currentArea);
    }
    for(auto visibleTile : event->visible) {
      updateTileRepresentation(visibleTile, currentArea);
    }
  }

  _mapPanel->render();
}

void LocalBackEnd::updateTileRepresentation(const IVec2& coords, ClientArea* currentArea) {
  auto tile = currentArea->getTile(coords);
  if(!tile) {
    _mapSource->setData(coords.x, coords.y, ' ', A_NORMAL);
    return;
  }

  const set<BObjectID>& contents = tile->getContents();
  if(contents.find(_characterID) != contents.end()) {
    Debug("Character object (" << _characterID << ") found at " << coords);
    _mapSource->setData(coords.x, coords.y, '@', A_BOLD | COLOR_PAIR(RED_ON_BLACK));
    return;
  }

  char c;
  switch(tile->getType()) {
    case TileType::Wall:   c = 'X'; break;
    case TileType::Ground: c = '.'; break;
    default:               c = '?'; break;
  }
  _mapSource->setData(coords.x, coords.y, c, currentArea->isTileShrouded(coords) ? A_NORMAL : A_BOLD);
}
