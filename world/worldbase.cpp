#include "world/worldbase.h"

WorldBase::WorldBase() {}

WorldBase::~WorldBase() {
  for(auto area : _areas) {
    delete area;
  }
}

AreaBase* WorldBase::getArea(const string& name) const {
  auto result = _namedAreas.find(name);
  if(result == _namedAreas.end()) { return 0; }
  else { return result->second; }
}

void WorldBase::addArea(AreaBase* area) {
  if(hasArea(area->getName())) {
    Warn("Duplicate area name " << area->getName() << " added to world");
  }
  _areas.push_back(area);
  _namedAreas[area->getName()] = area;
}

void WorldBase::addConnection(AreaBase* a, AreaBase* b) {
  auto aConnects = _connections.find(a),
       bConnects = _connections.find(b);
  if(aConnects == _connections.end()) {
    _connections.insert(make_pair(a, set<AreaBase*> { b }));
  } else {
    _connections[a].insert(b);
  }
  if(bConnects == _connections.end()) {
    _connections.insert(make_pair(b, set<AreaBase*> { a }));
  } else {
    _connections[b].insert(a);
  }
  a->addConnection(b->getName());
  b->addConnection(a->getName());
}

bool WorldBase::hasArea(const string& name) {
  return (_namedAreas.find(name) != _namedAreas.end());
}
