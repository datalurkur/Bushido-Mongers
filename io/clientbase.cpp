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
  sendToServer(&event);
}

void ClientBase::loadCharacter(BObjectID id) {
  LoadCharacterEvent event(id);
  sendToServer(&event);
}

void ClientBase::unloadCharacter() {
  UnloadCharacterEvent event;
  sendToServer(&event);
}

void ClientBase::moveCharacter(const IVec2& dir) {
  MoveCharacterEvent event(dir);
  sendToServer(&event);
}

void ClientBase::processEvent(GameEvent* event) {
  switch(event->type) {
    case GameEventType::AreaData: {
      struct AreaDataEvent* e = (struct AreaDataEvent*)event;
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
      struct TileDataEvent* e = (struct TileDataEvent*)event;
      Debug("Received data about tile at " << e->pos);
      if(!_currentArea) {
        Error("Can't contextualize tile data with no current area set");
        break;
      }
      Tile* tile = _currentArea->getTile(e->pos);
      if(!tile) {
        tile = new Tile(_currentArea, e->pos, e->type);
        _currentArea->setTile(e->pos, tile);
      } else {
        tile->setType(e->type);
      }
      _currentArea->revealTile(e->pos);
      break;
    }
    case GameEventType::TileShrouded: {
      struct TileShroudedEvent* e = (struct TileShroudedEvent*)event;
      Debug("Tile at " << e->pos << " is now shrouded");
      _currentArea->shroudTile(e->pos);
      break;
    }
    case GameEventType::CharacterReady:
      Debug("Character is ready");
      break;
    case GameEventType::CharacterNotReady:
      Debug("Character not ready - " << ((CharacterNotReadyEvent*)event)->reason);
      break;
    case GameEventType::CharacterMoved:
      Debug("Character moved");
      break;
    case GameEventType::MoveFailed:
      Debug("Failed to move - " << ((MoveFailedEvent*)event)->reason);
      break;
    default:
      Warn("Unhandled game event type " << event->type);
      break;
  }
}
