#include "game/objectobserver.h"
#include "util/structure.h"

// This basically only exists so that std::map can instantiate it properly
ObjectObserver::ObjectObserver(): _currentArea(0), _tileData(300), _objectData(300) {
}

ObjectObserver::ObjectObserver(BObjectManager* manager): _manager(manager), _currentArea(0), _tileData(300), _objectData(300) {
}

void ObjectObserver::areaChanges(Area* area, const set<IVec2>& view, EventQueue* results) {
  // Reset state
  _currentArea = area;
  _tileData.clear();
  _currentView.clear();

  // Send the area information
  results->pushEvent(new AreaDataEvent(area->getName(), area->getPos(), area->getSize()));

  // Send view information
  viewChanges(view, results);
}

void ObjectObserver::viewChanges(const set<IVec2>& newView, EventQueue* results) {
  time_t currentTime = Clock.getTime();

  set<IVec2> shrouded, visible;
  map<IVec2, TileDatum> updated;

  // Compare the new and old perspectives
  setComplement(_currentView, newView, shrouded, visible);

  // Determine which tiles (or contents) have changed since they were last seen
  set<IVec2> newlyVisible;
  for(auto c : visible) {
    auto lastChanged = _currentArea->getTile(c)->lastChanged();
    if(!_tileData.has(c) || (_tileData.get(c) <= lastChanged)) {
/*
      // DEBUG
      if(!_tileData.has(c)) {
        Debug("Newly visible tile " << c << " has not yet been sent");
      } else {
        Debug("Newly visible tile " << c << " was last updated " << _tileData.get(c) << ", new data will be sent");
      }
*/

      TileBase* tile = _currentArea->getTile(c);
      updated.insert(make_pair(c, tile));
      _tileData.set(c, currentTime);

      // Check for updated object data
      for(auto object : tile->getContents()) {
        objectViewed(object, results);
      }
    } else {
      //Debug("Visible tile " << c << " was last updated " << _tileData.get(c) << ", and is up-to-date (last changed " << lastChanged << ")");
      newlyVisible.insert(c);
    }
  }

  // Send tile data
  //Debug("Sending tile data with " << newlyVisible.size() << " newly visible tiles, " << updated.size() << " updated tiles, and " << shrouded.size() << " shrouded tiles");
  results->pushEvent(new TileDataEvent(shrouded, newlyVisible, updated));

  _currentView = newView;
}

void ObjectObserver::objectViewed(BObjectID id, EventQueue* results) {
  //Debug("Player observes object " << id);
  BObject* object = _manager->getObject(id);
  if(!_objectData.has(id) || (_objectData.get(id) < object->lastChanged())) {
    //Debug("Object has updated, data will be sent");
    results->pushEvent(new ObjectDataEvent(id, object->getProto()->name));
    _objectData.set(id, Clock.getTime());
  } else {
    //Debug("Object has not updated since being seen last");
  }
}

bool ObjectObserver::canSee(Area* area, const IVec2& location) {
  return (_currentArea == area) && (_currentView.find(location) != _currentView.end());
}
