#include "game/objectobserver.h"

ObjectObserver::ObjectObserver() {
}

bool ObjectObserver::needsUpdate(const BObject* bobject);
  BObjectID id = bobject->getID();

  // FIXME
  time_t lastUpdated = ;

  bool ret = (!_lastSeen.has(id) || _lastSeen.get(id) < lastupdated);
  _lastSeen.set();
  return ret;
}
