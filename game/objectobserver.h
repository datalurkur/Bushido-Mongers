#ifndef OBJECTOBSERVER_H
#define OBJECTOBSERVER_H

#include "util/timedmap.h"
#include "game/bobjecttypes.h"
#include "game/bobjectmanager.h"
#include "world/area.h"
#include "io/eventqueue.h"

class ObjectObserver {
public:
  ObjectObserver();
  ObjectObserver(BObjectManager* manager);

  void areaChanges(Area* area, const set<IVec2>& view, EventQueue& results);
  void viewChanges(const set<IVec2>& newView, EventQueue& results);

  void objectViewed(BObjectID id, EventQueue& results);

  bool canSee(Area* area, const IVec2& location);

private:
  BObjectManager* _manager;
  Area* _currentArea;

  set<IVec2> _currentView;

  TimedMap<IVec2> _tileData;
  TimedMap<BObjectID> _objectData;
};

#endif
