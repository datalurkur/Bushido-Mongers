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
    case TileData: {
      if(!_currentArea) {
        Error("Can't contextualize tile data with no current area set");
        break;
      }

      struct TileDataEvent* e = (struct TileDataEvent*)event;

      // Deal with visible tiles
      for(auto v : e->visible) {
        Debug("Tile at " << v << " is now visible");
        _currentArea->revealTile(v);
      }

      // Deal with shrouded tiles
      for(auto s : e->shrouded) {
        Debug("Tile at " << s << " is now shrouded");
        _currentArea->shroudTile(s);
      }

      // Deal with updated tiles
      for(auto u : e->updated) {
        Debug("Tile data at " << u.first << " has been updated");
        _currentArea->revealTile(u.first);
        _currentArea->setTile(u.first, new ClientTile(
          u.second.type,
          move(u.second.contents)
        ));
      }

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
