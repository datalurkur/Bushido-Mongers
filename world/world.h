#ifndef WORLD_H
#define WORLD_H

#include "world/area.h"

#include <list>
#include <map>
#include <set>

using namespace std;

class World {
  friend class WorldGenerator;

public:
  World();
  ~World();

protected:
  void addArea(Area* area);
  void addConnection(Area* a, Area* b);

private:
  list<Area*> _areas;
  map<Area*, set<Area*> > _connections;
};

#endif
