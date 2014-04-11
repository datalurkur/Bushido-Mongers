#include "game/observable.h"

Observable::Observable() { markChanged(); }
time_t Observable::lastChanged() const { return _lastChanged; }
void Observable::setLastChanged(time_t changed) { _lastChanged = changed; }
void Observable::markChanged() { _lastChanged = Clock.getTime(); }
