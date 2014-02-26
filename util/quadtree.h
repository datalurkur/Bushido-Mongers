#ifndef QUADTREE_H
#define QUADTREE_H

#include "util/log.h"

#include <list>
#include <vector>
#include <algorithm>

using namespace std;

class ObjectOutOfBoundsException : public exception {
  virtual const char* what() const throw() { return "Object is unbounded by the quadtree"; }
};

template <typename S>
class QuadTreePointObject {
public:
  QuadTreePointObject(S x, S y): _x(x), _y(y) {}

  S getX() const { return _x; }
  S getY() const { return _y; }

protected:
  S _x, _y;
};

template <typename S>
class QuadTreeBoxObject : public QuadTreePointObject<S> {
public:
  QuadTreeBoxObject(S x, S y, S maxX, S maxY):
    QuadTreePointObject<S>(x, y), _maxX(maxX), _maxY(maxY), _midX((maxX - x) / 2 + x), _midY((maxY - y) / 2 + y) {}

  S getMidX() const { return _midX; }
  S getMidY() const { return _midY; }
  S getMaxX() const { return _maxX; }
  S getMaxY() const { return _maxY; }

protected:
  S _maxX, _maxY, _midX, _midY;
};

template <typename T, typename S>
class QuadTree {
protected:
  enum Quadrant { None, LL, LR, UL, UR };

public:
  QuadTree(S x, S y, S maxX, S maxY, QuadTree<T,S>* parent = 0);
  virtual ~QuadTree();

  void getObjects(list<T>& objects);
  virtual void getObjects(S x, S y, S maxX, S maxY, list<T>& objects) = 0;
  virtual void getClosestNObjects(S x, S y, unsigned int n, list<T>& objects) = 0;

protected:
  S _x, _y, _maxX, _maxY;
  S _midX, _midY;

  list<T> _objects;

  QuadTree<T,S>* _ll;
  QuadTree<T,S>* _ul;
  QuadTree<T,S>* _lr;
  QuadTree<T,S>* _ur;

  QuadTree<T,S>* _parent;
};

template <typename T, typename S>
QuadTree<T,S>::QuadTree(S x, S y, S maxX, S maxY, QuadTree<T,S>* parent):
  _x(x), _y(y), _maxX(maxX), _maxY(maxY), _ll(0), _ul(0), _lr(0), _ur(0), _parent(parent) {}

template <typename T, typename S>
QuadTree<T,S>::~QuadTree() {
  if(_ll != 0) { delete _ll; }
  if(_ul != 0) { delete _ul; }
  if(_ur != 0) { delete _ur; }
  if(_lr != 0) { delete _lr; }
}

template <typename T, typename S>
void QuadTree<T,S>::getObjects(list<T>& objects) {
  if(_ll != 0) { _ll->getObjects(objects); }
  if(_lr != 0) { _lr->getObjects(objects); }
  if(_ul != 0) { _ul->getObjects(objects); }
  if(_ur != 0) { _ur->getObjects(objects); }
  objects.insert(objects.end(), _objects.begin(), _objects.end());
}

#endif
