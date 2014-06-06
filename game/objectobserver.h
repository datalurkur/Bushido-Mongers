#ifndef OBJECTOBSERVER_H
#define OBJECTOBSERVER_H

#include "util/timedmap.h"
#include "game/bobjecttypes.h"
#include "world/area.h"
#include "io/eventqueue.h"

class ObjectObserver {
public:
  ObjectObserver();

  void areaChanges(Area* area, const set<IVec2>& view, EventQueue& results);
  void viewChanges(const set<IVec2>& currentView, EventQueue& results);

private:
  Area* _currentArea;

  set<IVec2> _previousView;

  TimedMap<IVec2> _tileData;
  TimedMap<BObjectID> _objectData;
};

#endif
