#ifndef WORLD_H
#define WORLD_H

#include "world/worldbase.h"
#include "world/area.h"

using namespace std;

class World: public WorldBase {
public:
  World();

  void generateGraphVizFile(const string& filename);
  Area* getRandomArea() const;

  friend class WorldGenerator;
};

#endif
