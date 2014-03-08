#ifndef GENERATOR_H
#define GENERATOR_H

#include "world/world.h"

class Feature {
public:
  Feature(int x, int y, int r): _x(x), _y(y), _r(r) {}
  int getX() const { return _x; }
  int getY() const { return _y; }
  int getRadius() const { return _r; }
  void setArea(Area* a) { _area = a; }
  Area* getArea() { return _area; }

private:
  int _x, _y;
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
  static void GenerateCave(Area* area, float openness, float density);

private:
  // No instantiation for you!
  WorldGenerator() {}
};

#endif
