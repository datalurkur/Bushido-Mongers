#include "world/clientworld.h"
#include "world/clientarea.h"
#include "io/gameevent.h"

ClientWorld::ClientWorld(): _currentArea(0) {}

void ClientWorld::processWorldEvent(GameEvent* event, EventQueue& results) {
  switch(event->type) {
    case AreaData: {
      struct AreaDataEvent* e = (struct AreaDataEvent*)event;
      Debug("Received data for area " << e->name);

      if(hasArea(e->name)) {
        Debug("Area data already present for " << e->name);
      } else {
        ClientArea* area = new ClientArea(e->name, e->pos, e->size);
        addArea(area);
        _currentArea = area;
        Debug("Current area set to " << _currentArea);
      }
      break;
    }
    case TileVisible: {
      struct TileVisibleEvent* e = (struct TileVisibleEvent*)event;
      Debug("Tile at " << e->pos << " is now visible (last modified " << e->lastChanged << ")");
      if(!_currentArea) {
        Error("Can't contextualize tile data with no current area set");
        break;
      }
      _currentArea->revealTile(e->pos);

      ClientTile* tile = (ClientTile*)_currentArea->getTile(e->pos);
      if(!tile || tile->lastChanged() <= e->lastChanged) {
        Debug("Fetching tile data for " << e->pos);
        results.pushEvent(new GetTileDataEvent(e->pos));
      } else {
        Debug("Tile data up-to-date");
      }
      break;
    }
    case TileData: {
      struct TileDataEvent* e = (struct TileDataEvent*)event;
      if(!_currentArea) {
        Error("Can't contextualize tile data with no current area set");
        break;
      }
      Debug("Received tile data for " << e->pos);
      ClientTile* newTile = new ClientTile(e->type, e->contents, e->lastChanged);
      _currentArea->setTile(e->pos, newTile);
      break;
    }
    case TileShrouded: {
      struct TileShroudedEvent* e = (struct TileShroudedEvent*)event;
      if(!_currentArea) {
        Error("Can't contextualize tile data with no current area set");
        break;
      }
      Debug("Tile at " << e->pos << " is now shrouded");
      _currentArea->shroudTile(e->pos);
      break;
    }
    default:
      Warn("Unhandled event type passing through client world - " << event->type);
      break;
  }
}

ClientArea* ClientWorld::getCurrentArea() {
  return _currentArea;
}
