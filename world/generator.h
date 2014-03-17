#ifndef GENERATOR_H
#define GENERATOR_H

#include "world/world.h"
#include "util/vector.h"

class Feature {
public:
  Feature(int x, int y, int r): _pos(Vec2(x, y)), _r(r) {}
  Feature(Vec2 pos, int r): _pos(pos), _r(r) {}
  const Vec2& getPos() const { return _pos; }
  int getRadius() const { return _r; }
  void setArea(Area* a) { _area = a; }
  Area* getArea() { return _area; }

private:
  Vec2 _pos;
  int _r;
  Area* _area;
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
  static void ParseAreas(Area* area, map<int, set<Vec2> >& grouped);

private:
  // No instantiation for you!
  WorldGenerator() {}
};

#endif
