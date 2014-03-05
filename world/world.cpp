#include "world/world.h"

World::World() {
}

World::~World() {
  for(auto area : _areas) {
    delete area;
  }
}

void World::addArea(Area* area) {
  _areas.push_back(area);
}

void World::addConnection(Area* a, Area* b) {
  _connections[a].insert(b);
  _connections[b].insert(a);
  a->addConnection(b);
  b->addConnection(a);
}
