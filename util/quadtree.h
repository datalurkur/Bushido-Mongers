#ifndef QUADTREE_H
#define QUADTREE_H

#include "util/log.h"
#include "util/assertion.h"

#include <set>
#include <map>
//#include <algorithm>

using namespace std;

class ObjectOutOfBoundsException : public exception {
  virtual const char* what() const throw() { return "Object is unbounded by the quadtree"; }
};

template <typename T>
class QuadTree {
private:
  struct BB {
    int x;
    int y;
    int maxX;
    int maxY;

    BB(int mX, int mY, int mMaxX, int mMaxY): x(mX), y(mY), maxX(mMaxX), maxY(mMaxY) {}
  };

public:
  QuadTree(int x, int y, int maxX, int maxY, int depth, QuadTree<T>* parent = 0);
  virtual ~QuadTree();

  void findObjects(int x, int y, int maxX, int maxY, set<T>& objects);
  void addObject(T object, int x, int y, int maxX, int maxY);
  void moveObject(T object, int x, int y, int maxX, int maxY);
  void removeObject(T object);

  void debug();

private:
  int _x, _y, _maxX, _maxY;
  int _midX, _midY;

  map<T, BB> _objects;

  QuadTree<T>* _ll;
  QuadTree<T>* _ul;
  QuadTree<T>* _lr;
  QuadTree<T>* _ur;

  set<T> _llObjects;
  set<T> _ulObjects;
  set<T> _lrObjects;
  set<T> _urObjects;

  QuadTree<T>* _parent;
};

template <typename T>
QuadTree<T>::QuadTree(int x, int y, int maxX, int maxY, int depth, QuadTree<T>* parent):
  _x(x), _y(y), _maxX(maxX), _maxY(maxY), _parent(parent) {
  _midX = (_x + _maxX) / 2;
  _midY = (_y + _maxY) / 2;
  ASSERT(_midX > _x && _midY > _y, "Depth too large given QuadTree size");
  if(depth > 1) {
    _ll = new QuadTree(       _x,        _y, _midX, _midY, depth - 1, this);
    _lr = new QuadTree(_midX + 1,        _y, _maxX, _midY, depth - 1, this);
    _ur = new QuadTree(_midX + 1, _midY + 1, _maxX, _maxY, depth - 1, this);
    _ul = new QuadTree(       _x, _midY + 1, _midX, _maxY, depth - 1, this);
  } else {
    _ll = _lr = _ul = _ur = 0;
  }
}

template <typename T>
QuadTree<T>::~QuadTree() {
  if(_ll != 0) { delete _ll; }
  if(_ul != 0) { delete _ul; }
  if(_ur != 0) { delete _ur; }
  if(_lr != 0) { delete _lr; }
}

template <typename T>
void QuadTree<T>::findObjects(int x, int y, int maxX, int maxY, set<T>& objects) {
  if(_ll &&    x <= _midX &&    y <= _midY) { _ll->findObjects(x, y, maxX, maxY, objects); }
  if(_lr && maxX >= _midX &&    y <= _midY) { _lr->findObjects(x, y, maxX, maxY, objects); }
  if(_ur && maxX >= _midX && maxY >= _midY) { _ur->findObjects(x, y, maxX, maxY, objects); }
  if(_ul &&    x <= _midX && maxY >= _midY) { _ul->findObjects(x, y, maxX, maxY, objects); }

  for(auto objectPair : _objects) {
    if(objectPair.second.x    <= maxX &&
       objectPair.second.y    <= maxY &&
       objectPair.second.maxX >= x &&
       objectPair.second.maxY >= y) {
      objects.insert(objectPair.first);
    }
  }
}

template <typename T>
void QuadTree<T>::addObject(T object, int x, int y, int maxX, int maxY) {
  ASSERT(maxX >= x && maxY >= y, "Object max dimension must exceed its minimum dimension");
  ASSERT(x >= _x && y >= _y && maxX <= _maxX && maxY <= _maxY, "Object dimensions must exist within the confines of the quadtree");
         if(_ll && maxX <= _midX && maxY <= _midY) {
    _ll->addObject(object, x, y, maxX, maxY);
    _llObjects.insert(object);
  } else if(_lr &&     x > _midX && maxY <= _midY) {
    _lr->addObject(object, x, y, maxX, maxY);
    _lrObjects.insert(object);
  } else if(_ur &&     x > _midX &&     y > _midY) {
    _ur->addObject(object, x, y, maxX, maxY);
    _urObjects.insert(object);
  } else if(_ul && maxX <= _midX &&     y > _midY) {
    _ul->addObject(object, x, y, maxX, maxY);
    _ulObjects.insert(object);
  } else {
    _objects.insert(make_pair(object, BB(x, y, maxX, maxY)));
  }
}

template <typename T>
void QuadTree<T>::moveObject(T object, int x, int y, int maxX, int maxY) {
  removeObject(object);
  addObject(object, x, y, maxX, maxY);
}

template <typename T>
void QuadTree<T>::removeObject(T object) {
  if(_objects.find(object) != _objects.end()) {
    _objects.erase(object);
  } else if(_ll && _llObjects.find(object) != _llObjects.end()) {
    _ll->removeObject(object);
    _llObjects.erase(object);
  } else if(_lr && _lrObjects.find(object) != _lrObjects.end()) {
    _lr->removeObject(object);
    _lrObjects.erase(object);
  } else if(_ur && _urObjects.find(object) != _urObjects.end()) {
    _ur->removeObject(object);
    _urObjects.erase(object);
  } else if(_ul && _ulObjects.find(object) != _ulObjects.end()) {
    _ul->removeObject(object);
    _ulObjects.erase(object);
  }
}

template <typename T>
void QuadTree<T>::debug() {
  Info("Quadtree contains " << _objects.size() << " objects");
  for(auto objectPair : _objects) {
    Info("-Object " << objectPair->first << " starts at (" << objectPair->second.x << "," << objectPair->second.y << ") and extends to (" << objectPair->second.maxX << "," << objectPair->second.maxY << ")");
  }

  if(_ll) { _ll->debug(); }
  if(_lr) { _lr->debug(); }
  if(_ur) { _ur->debug(); }
  if(_ul) { _ul->debug(); }
}

#endif
