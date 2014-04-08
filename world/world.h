#ifndef WORLD_H
#define WORLD_H

#include "world/area.h"

#include <list>
#include <map>
#include <set>
#include <string>

using namespace std;

class World {
  friend class WorldGenerator;
  friend class ClientBase;

public:
  World();
  ~World();

  void generateGraphVizFile(const string& filename);

  Area* getArea(const string& name) const;
  Area* getRandomArea() const;

protected:
  void addArea(Area* area);
  bool hasArea(const string& name);
  void addConnection(Area* a, Area* b);

private:
  list<Area*> _areas;
  map<Area*, set<Area*> > _connections;
  map<string, Area*> _namedAreas;
};

#endif
