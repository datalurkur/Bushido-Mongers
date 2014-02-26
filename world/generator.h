#ifndef GENERATOR_H
#define GENERATOR_H

#include "world/world.h"
#include "util/pointquadtree.h"

class WorldGenerator {
public:
  static World* CloudGenerate(int size, float sparseness);

private:
  // No instantiation for you!
  WorldGenerator() {}
};

class Feature : public QuadTreePointObject<int> {
public:
  Feature(int x, int y, int r): QuadTreePointObject(x, y), _r(r) {}
  int getRadius() const { return _r; }

private:
  int _r;
};

class FeatureDistanceComparator {
public:
  FeatureDistanceComparator(Feature* f): _f(f) {}
  bool operator()(const Feature* f1, const Feature* f2) const { return distance(f1) < distance(f2); }

private:
  int distance(const Feature* f) const {
    int dX = f->getX() - _f->getX();
    int dY = f->getY() - _f->getY();
    int dR = f->getRadius() + _f->getRadius();
    return (dX * dX) + (dY * dY) - (dR * dR);
  }

private:
  Feature* _f;
};

#endif
