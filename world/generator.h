#ifndef GENERATOR_H
#define GENERATOR_H

#include "world/world.h"
#include "util/vector.h"

struct Feature {
  Feature(int x, int y, int r): pos(IVec2(x, y)), radius(r) {}
  Feature(IVec2 pos, int r): pos(pos), radius(r) {}

  IVec2 pos;
  int radius;
  Area* area;
};

class WorldGenerator {
public:
  enum ConnectionMethod {
    MaxDistance,
    Centralization,
    Random
  };

  static World* GenerateWorld(int size, float sparseness, float connectedness, ConnectionMethod connectionMethod);
  static void PlaceAreaTransitions(Area* area);
  static void GenerateCave(Area* area, float openness, float density);
  static void GenerateHallways(Area* area, float density);

//private:
  static void ParseAreas(Area* area, map<int, set<IVec2> >& grouped);

private:
  // No instantiation for you!
  WorldGenerator() {}
};

#endif
