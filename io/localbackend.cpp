#include "io/localbackend.h"
#include "io/gameevent.h"
#include "world/clientarea.h"
#include "curseme/renderer.h"

LocalBackEnd::LocalBackEnd(): _consumerShouldDie(false), _eventsReady(false), _mapSource(0), _characterID(0), _lastPlayerLocation(0,0), _cursorEnabled(false), _cursorLocation(0,0) {
  wrefresh(stdscr);

  int w, h;
  getmaxyx(stdscr, h, w);

  // Create the main window to fill the whole screen, with 10 rows of padding at the bottom for the log window
  _mainWindow = new Window(Window::Alignment::TOP_CENTER, 1.0f, 1.0f, 0, 10, 0, 0, 0);
  // Create the log window as a 10-row high bar at the bottom of the screen
  _logWindow = new Window(Window::Alignment::BOTTOM_CENTER, w, 10, 0, 0, 0);
  // Split the main window 80 / 20 between the map and the info bar
  _mapWindow = new Window(Window::Alignment::CENTER_LEFT, 0.8f, 1.0f, 0, 0, 0, 0, _mainWindow);
  _infoWindow = new Window(Window::Alignment::CENTER_RIGHT, 0.2f, 1.0f, 0, 0, 0, 0, _mainWindow);

  // Create the log panel
  _logPanel = new CursesLogWindow(_logWindow);

  // Create the map panel
  _mapPanel = new RenderTarget(_mapWindow);

  // Create the object menu
  _objectMenu = new DynamicMenu("Objects in tile", _infoWindow);

  _eventConsumer = thread(&LocalBackEnd::consumeEvents, this);

  _objectRepresentation.load("object.rep");
}

LocalBackEnd::~LocalBackEnd() {
  // Tell the event consumer that it should die and wait for it to do so
  if(_eventConsumer.joinable()) {
    _consumerShouldDie = true;
    _eventsReadyCondition.notify_all();
    _eventConsumer.join();
  }

  delete _mapPanel;
  delete _mapWindow;
  delete _infoWindow;
  delete _mainWindow;
  delete _logWindow;
  delete _logPanel;
}

void LocalBackEnd::enableCursor(bool enabled) {
  _cursorEnabled = enabled;
  if(enabled) {
    _cursorLocation = _lastPlayerLocation;
  } else {
    _mapPanel->setCenter(_lastPlayerLocation);
  }
  ClientArea* currentArea = _world.getCurrentArea();
  updateTileRepresentation(_cursorLocation, currentArea);
  _mapPanel->render();
  updateInfoPanel();
}

void LocalBackEnd::moveCursor(const IVec2& dir) {
  IVec2 oldLocation = _cursorLocation;
  _cursorLocation += dir;

  ClientArea* currentArea = _world.getCurrentArea();
  const IVec2 areaSize = currentArea->getSize();
  if(_cursorLocation.x < 0) { _cursorLocation.x = 0; }
  if(_cursorLocation.y < 0) { _cursorLocation.y = 0; }
  if(_cursorLocation.x >= areaSize.x) { _cursorLocation.x = areaSize.x - 1; }
  if(_cursorLocation.y >= areaSize.y) { _cursorLocation.y = areaSize.y - 1; }

  if(oldLocation != _cursorLocation) {
    updateTileRepresentation(oldLocation, currentArea);
    updateTileRepresentation(_cursorLocation, currentArea);
    _mapPanel->render();
  }
  updateInfoPanel();
}

bool LocalBackEnd::sendToClient(EventQueue* queue) {
  unique_lock<mutex> lock(_eventLock);
  _events.appendQueue(queue);
  _eventsReady = true;
  _eventsReadyCondition.notify_all();
  return true;
}

bool LocalBackEnd::sendToClient(GameEvent* event) {
  unique_lock<mutex> lock(_eventLock);
  _events.pushEvent(event->clone());
  _eventsReady = true;
  _eventsReadyCondition.notify_all();
  return true;
}

void LocalBackEnd::consumeEvents() {
  while(!_consumerShouldDie) {
    unique_lock<mutex> lock(_eventLock);
    while(!_eventsReady && !_consumerShouldDie) _eventsReadyCondition.wait(lock);

    if(!_events.empty()) {
      for(auto e : _events) {
        consumeSingleEvent(e);
      }
      _events.clear();
    }
  }
}

void LocalBackEnd::consumeSingleEvent(GameEvent* event) {
  switch(event->type) {
    case RawData:
      Debug("Received raw data from server");
      unpackRaws((RawDataEvent*)event);
      break;
    case AreaData:
      Debug("Area data received from server");
      _world.processWorldEvent(event);
      changeArea();
      break;
    case TileData:
      //Debug("Tile data received from server");
      _world.processWorldEvent(event);
      updateMap((TileDataEvent*)event);
      break;
    case ObjectData:
      updateObject((ObjectDataEvent*)event);
      break;
    case CharacterReady:
      Debug("Character is ready");
      changeArea();
      _characterID = ((CharacterReadyEvent*)event)->ID;
      break;
    case CharacterNotReady:
      Debug("Character not ready - " << ((CharacterNotReadyEvent*)event)->reason);
      break;
    case ThingMoved:
      moveObject((ThingMovedEvent*)event);
      break;
    case MoveFailed:
      Debug("Failed to move - " << ((MoveFailedEvent*)event)->reason);
      break;
    default:
      Warn("Unhandled game event type " << event->type);
      break;
  }
}

void LocalBackEnd::unpackRaws(RawDataEvent* event) {
  istringstream stream(event->packed);
  if(!_raw.unpack(stream)) {
    Error("Failed to unpack raws from server");
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

void LocalBackEnd::updateObject(ObjectDataEvent* event) {
  Debug("Updating data for object " << event->ID << " (typed " << event->prototype << ")");
  _objects[event->ID] = BObjectStub();
  _objects[event->ID].prototype = event->prototype;
}

void LocalBackEnd::moveObject(ThingMovedEvent* event) {
  ClientArea* currentArea = _world.getCurrentArea();

  #pragma message "Fix this so it displays something intelligent and useful"
  if(!currentArea) { return; }

  auto sourceTile = currentArea->getTile(event->source);
  auto destTile   = currentArea->getTile(event->destination);

  if(sourceTile) {
    sourceTile->removeObject(event->object);
    updateTileRepresentation(event->source, currentArea);
  }
  if(destTile) {
    destTile->addObject(event->object);
    updateTileRepresentation(event->destination, currentArea);
  }

  if(sourceTile || destTile) {
    _mapPanel->render();
  }
}

void LocalBackEnd::updateTileRepresentation(const IVec2& coords, ClientArea* currentArea) {
  if(_cursorEnabled && _cursorLocation == coords) {
    _mapSource->setData(coords.x, coords.y, 'X', A_BLINK | COLOR_PAIR(BLUE_ON_BLACK));
    _mapPanel->setCenter(coords);
    return;
  }

  auto tile = currentArea->getTile(coords);
  if(!tile) {
    _mapSource->setData(coords.x, coords.y, ' ', A_NORMAL);
    return;
  }

  const set<BObjectID>& contents = tile->getContents();
  if(contents.find(_characterID) != contents.end()) {
    _mapSource->setData(coords.x, coords.y, '@', A_BOLD | COLOR_PAIR(RED_ON_BLACK));
    _lastPlayerLocation = coords;
    if(!_cursorEnabled) {
      _mapPanel->setCenter(coords);
      updateInfoPanel();
    }
    return;
  }

  chtype c;
  if(contents.size() > 0) {
    set<const ProtoBObject*> protos;
    for(auto obj : contents) {
      auto objectStub = _objects.find(obj);
      if(objectStub == _objects.end()) { continue; }
      const ProtoBObject* proto = _raw.getObject(objectStub->second.prototype);
      if(proto) {
        protos.insert(proto);
      } else {
        Debug("No prototype found for " << objectStub->second.prototype);
      }
    }
    c = _objectRepresentation.get(protos);
  } else {
    // Generate a symbol by terrain
    TileType tileType = tile->getType();
    if(tileType == TileType::Wall) {
      short wallBits = 0;
      for(int i = -1; i <= 1; i++) {
        for(int j = -1; j <= 1; j++) {
          if(i == j && i == 0) { continue; }
          IVec2 local = coords + IVec2(i, j);

          TileBase* tile = 0;
          if(local.x < 0 || local.x >= currentArea->getSize().x ||
             local.y < 0 || local.y >= currentArea->getSize().y ||
             !(tile = currentArea->getTile(local)) ||
             tile->getType() == TileType::Wall) {
            wallBits |= MARCHING_SQUARES_BIT(i, j);
          }
        }
      }
      c = getMarchingSquaresRepresentation(wallBits);
    } else if(tileType == TileType::Ground) {
      c = '.';
    } else {
      c = '?';
    }
  }
  _mapSource->setData(coords.x, coords.y, c, currentArea->isTileShrouded(coords) ? A_NORMAL : A_BOLD);
}

void LocalBackEnd::updateInfoPanel() {
  IVec2 p;
  if(_cursorEnabled) {
    p = _cursorLocation;
  } else {
    p = _lastPlayerLocation;
  }
  _objectMenu->clearChoices();

  ClientArea* currentArea = _world.getCurrentArea();
  if(!currentArea) {
    return;
  }
  TileBase* tile = currentArea->getTile(p);
  if(!tile) {
    return;
  }

  for(auto obj : tile->getContents()) {
    auto objectStub = _objects.find(obj);
    if(objectStub == _objects.end()) { continue; }
    const ProtoBObject* proto = _raw.getObject(objectStub->second.prototype);
    _objectMenu->addChoice(proto->name);
  }
}
