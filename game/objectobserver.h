#ifndef OBJECTOBSERVER_H
#define OBJECTOBSERVER_H

#include "util/timedmap.h"
#include "game/bobjecttypes.h"

class ObjectObserver {
public:
  ObjectObserver();

  void areaChanges(Area* area);
  void viewChanges(const set<IVec2>* previousView, const set<IVec2>& currentView);

private:
  Area* _currentArea;
  TimedMap<IVec2> _tileData;
  TimedMap<BObjectID> _objectData;
};

#endif
