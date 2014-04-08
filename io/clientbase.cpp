#include "io/clientbase.h"
#include "io/gameevent.h"
#include "world/world.h"

ClientBase::ClientBase(): _currentArea(0) {
  _world = new World();
}

ClientBase::~ClientBase() {
  delete _world;
}

void ClientBase::createCharacter(const string& name) {
  // In the future, we'll pass config data into this
  CreateCharacterEvent event(name);
  sendEvent(event);
}

void ClientBase::loadCharacter(BObjectID id) {
  LoadCharacterEvent event(id);
  sendEvent(event);
}

void ClientBase::unloadCharacter() {
  UnloadCharacterEvent event;
  sendEvent(event);
}

void ClientBase::processEvent(const GameEvent& event) {
  switch(event.type) {
  case GameEventType::AreaData: {
    struct AreaDataEvent* e = (struct AreaDataEvent*)&event;
    Debug("Received data for area " << e->name);
    if(_world->hasArea(e->name)) {
      Debug("Area data already present for " << e->name);
    } else {
      ClientArea* area = new ClientArea(e->name, e->pos, e->size);
      _world->addArea(area);
      _currentArea = area;
    }
    break;
  }
  case GameEventType::TileData: {
    struct TileDataEvent* e = (struct TileDataEvent*)&event;
    Debug("Received data about tile at " << e->pos);
    if(!_currentArea) {
      Error("Can't contextualize tile data with no current area set");
      break;
    }
    Tile* tile = _currentArea->getTile(e->pos);
    if(!tile) {
      tile = new Tile(e->type);
      _currentArea->setTile(e->pos, tile);
    } else {
      tile->setType(e->type);
    }
    _currentArea->revealTile(e->pos);
    break;
  }
  case GameEventType::TileShrouded: {
    struct TileShroudedEvent* e = (struct TileShroudedEvent*)&event;
    Debug("Tile at " << e->pos << " is now shrouded");
    _currentArea->shroudTile(e->pos);
    break;
  }
  default:
    Warn("Unhandled game event type " << event.type);
    break;
  }
}
