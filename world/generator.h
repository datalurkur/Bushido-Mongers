#ifndef GENERATOR_H
#define GENERATOR_H

#include "world/descriptor.h"
#include "world/world.h"
#include "util/vector.h"

#include <utility>
#include <map>
#include <vector>

using namespace std;

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

  static World* GenerateWorld(int size, float sparseness, float connectedness, ConnectionMethod connectionMethod, BObjectManager* objectManager);
  static void PlaceAreaTransitions(Area* area);

  static void GenerateArea(Area* area, const AreaDescriptor& descriptor, BObjectManager* objectManager);

  static void CarveNatural(Area* area, float openness, float density);

  static void ParseAreas(Area* area, map<int, set<IVec2> >& grouped);

private:
  static void FindGroupCenters(const map<int, set<IVec2> >& groups, map<int, IVec2>& centers, map<int, int>& sizes);
  static void ConnectGroupCenters(Area* area);

  static bool LessPairValues(const pair<int, int>& lhs, const pair<int, int>& rhs);

private:
  // No instantiation for you!
  WorldGenerator() {}
};

#endif
