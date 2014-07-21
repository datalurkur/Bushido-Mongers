#include "game/observable.h"
#include "util/log.h"

Observable::Observable() { markChanged(); }

time_t Observable::lastChanged() const { return _lastChanged; }
void Observable::setLastChanged(time_t changed) { _lastChanged = changed; }

void Observable::markChanged() {
  _lastChanged = Clock.getTime();
  //Debug("Object is marked as changed at " << _lastChanged);
  onChanged();
}

void Observable::onChanged() {}
