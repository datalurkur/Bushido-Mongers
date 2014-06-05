#include "game/objectobserver.h"

ObjectObserver::ObjectObserver(): _currentArea(0) {
}

void ObjectObserver::areaChanges(Area* area) {
}

void ObjectObserver::viewChanges(const set<IVec2>* previousView, const set<IVec2>& currentView) {
}
