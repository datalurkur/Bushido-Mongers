#include "game/objectobserver.h"
#include "util/structure.h"

ObjectObserver::ObjectObserver(): _currentArea(0), _tileData(300), _objectData(300) {
}

void ObjectObserver::areaChanges(Area* area, const set<IVec2>& view, EventQueue& results) {
  // Reset state
  _currentArea = area;
  _tileData.clear();
  _currentView.clear();

  // Send the area information
  results.pushEvent(new AreaDataEvent(area->getName(), area->getPos(), area->getSize()));

  // Send view information
  viewChanges(view, results);
}

void ObjectObserver::viewChanges(const set<IVec2>& newView, EventQueue& results) {
  time_t currentTime = Clock.getTime();

  set<IVec2> shrouded, visible;
  map<IVec2, TileDatum> updated;

  // Compare the new and old perspectives
  setComplement(_currentView, newView, shrouded, visible);

  // Determine which tiles (or contents) have changed since they were last seen
  set<IVec2> newlyVisible;
  for(auto c : visible) {
    if(!_tileData.has(c) || (_tileData.get(c) < _currentArea->getTile(c)->lastChanged())) {
/*
      // DEBUG
      if(!_tileData.has(c)) {
        Debug("Newly visible tile " << c << " has not yet been sent");
      } else {
        Debug("Newly visible tile " << c << " has been updated since " << _tileData.get(c));
      }
*/
      updated.insert(make_pair(c, TileDatum(_currentArea->getTile(c))));
      _tileData.set(c, currentTime);
    } else {
      //Debug("Newly visible tile " << c << " has seen no updates since " << tileData.get(c));
      newlyVisible.insert(c);
    }
  }

  // Send tile data
  //Debug("Sending tile data with " << newlyVisible.size() << " newly visible tiles, " << updated.size() << " updated tiles, and " << shrouded.size() << " shrouded tiles");
  results.pushEvent(new TileDataEvent(shrouded, newlyVisible, updated));

  _currentView = newView;
}

bool ObjectObserver::canSee(Area* area, const IVec2& location) {
  return (_currentArea == area) && (_currentView.find(location) != _currentView.end());
}
