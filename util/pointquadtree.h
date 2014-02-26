#ifndef POINTQUADTREE_H
#define POINTQUADTREE_H

#include "util/quadtree.h"

template <typename T, typename S>
class PointQuadTree : public QuadTree<T,S> {
public:
  PointQuadTree(S x, S y, S maxX, S maxY, unsigned int maxDepth, const list<T>& sourceObjects, unsigned int depth = 1, PointQuadTree<T,S>* parent = 0);

  void getObjects(S x, S y, S maxX, S maxY, list<T>& objects);
  void getClosestNObjects(S x, S y, unsigned int n, list<T>& objects);
};

template <typename T, typename S>
class PointDistanceComparator {
public:
  PointDistanceComparator(S x, S y);
  bool operator()(const T& p1, const T& p2) const;

private:
  S distanceFrom(const T& p) const;

private:
  S _x, _y;
};

template <typename T, typename S>
PointQuadTree<T,S>::PointQuadTree(S x, S y, S maxX, S maxY, unsigned int maxDepth, const list<T>& sourceObjects, unsigned int depth, PointQuadTree<T,S>* parent): QuadTree<T,S>(x, y, maxX, maxY, parent) {
  if(depth == 1) {
    for(auto object : sourceObjects) {
      if(object->getX() < this->_x ||
         object->getY() < this->_y ||
         object->getX() > this->_maxX ||
         object->getY() > this->_maxY
      ) {
        throw ObjectOutOfBoundsException();
      }
    }
  }
  auto numObjects = sourceObjects.size();
  if(depth < maxDepth && numObjects > 0) {
    //Debug("At depth " << depth + 1);

    // Compute the median object
    vector<S> xValues(numObjects);
    vector<S> yValues(numObjects);
    int i = 0;
    for(auto object : sourceObjects) {
      xValues[i] = object->getX();
      yValues[i] = object->getY();
      i++;
    }
    auto medianObject = numObjects / 2;
    nth_element(xValues.begin(), xValues.begin() + medianObject, xValues.end());
    nth_element(yValues.begin(), yValues.begin() + medianObject, yValues.end());
    this->_midX = xValues[medianObject];
    this->_midY = yValues[medianObject];
    //Debug("Median value of objects found to be " << this->_midX << "," << this->_midY);

    // Partition the objects
    list<T> unusedObjects;
    list<T> llObjects, lrObjects, ulObjects, urObjects;
    for(auto object : sourceObjects) {
      if(object->getX() < this->_midX) {
        if(object->getY() < this->_midY) {
          // Lower-left quadrant
          //Debug("Object at (" << object->getX() << "," << object->getY() << ") pushed into lower-left quadrant");
          llObjects.push_back(object);
        } else {
          // Upper-left quadrant
          //Debug("Object at (" << object->getX() << "," << object->getY() << ") pushed into upper-left quadrant");
          ulObjects.push_back(object);
        }
      } else {
        if(object->getY() < this->_midY) {
          // Lower-right quadrant
          //Debug("Object at (" << object->getX() << "," << object->getY() << ") pushed into lower-right quadrant");
          lrObjects.push_back(object);
        } else {
          // Upper-right quadrant
          //Debug("Object at (" << object->getX() << "," << object->getY() << ") pushed into upper-right quadrant");
          urObjects.push_back(object);
        }
      }
    }

    // Create the quads
    this->_ll = new PointQuadTree<T,S>(this->_x,    this->_y,    this->_midX, this->_midY, maxDepth, llObjects, depth + 1, this);
    this->_lr = new PointQuadTree<T,S>(this->_midX, this->_y,    this->_maxX, this->_midY, maxDepth, lrObjects, depth + 1, this);
    this->_ul = new PointQuadTree<T,S>(this->_x,    this->_midY, this->_midX, this->_maxY, maxDepth, ulObjects, depth + 1, this);
    this->_ur = new PointQuadTree<T,S>(this->_midX, this->_midY, this->_maxX, this->_maxY, maxDepth, urObjects, depth + 1, this);

    // Consume the remaining objects
    this->_objects = unusedObjects;
  } else if(numObjects > 0) {
    // This is a leaf node, consume all of the objects
    this->_objects = sourceObjects;
  }
}

template <typename T, typename S>
void PointQuadTree<T,S>::getObjects(S x, S y, S maxX, S maxY, list<T>& objects) {
  for(auto object : this->_objects) {
    if(object->getX() > maxX || object->getY() > maxY || object->getX() < x || object->getY() < y) { continue; }
    objects.push_back(object);
  }

  if(this->_ll && x < this->_midX && y < this->_midY) {
    this->_ll->getObjects(x, y, maxX, maxY, objects);
  }

  if(this->_ul && x < this->_midX && maxY > this->_midY) {
    this->_ul->getObjects(x, y, maxX, maxY, objects);
  }

  if(this->_lr && maxX > this->_midX && y < this->_midY) {
    this->_lr->getObjects(x, y, maxX, maxY, objects);
  }

  if(this->_ur && maxX > this->_midX && maxY > this->_midY) {
    this->_ur->getObjects(x, y, maxX, maxY, objects);
  }
}

template <typename T, typename S>
void PointQuadTree<T,S>::getClosestNObjects(S x, S y, unsigned int n, list<T>& objects) {
  typename QuadTree<T,S>::Quadrant q = QuadTree<T,S>::Quadrant::None;
  if(x < this->_midX) {
    if     (this->_ll && y <  this->_midY) { q = QuadTree<T,S>::Quadrant::LL; }
    else if(this->_ul && y >= this->_midY) { q = QuadTree<T,S>::Quadrant::UL; }
  } else {
    if     (this->_lr && y <  this->_midY) { q = QuadTree<T,S>::Quadrant::LR; }
    else if(this->_ur && y >= this->_midY) { q = QuadTree<T,S>::Quadrant::UR; }
  }

  switch(q) {
  case QuadTree<T,S>::Quadrant::LL:
    //Debug("Checking lower-left quadrant (" << x << " is less than " << this->_midX << " and " << y << " is less than " << this->_midY);
    this->_ll->getClosestNObjects(x, y, n, objects);
    break;
  case QuadTree<T,S>::Quadrant::UL:
    //Debug("Checking upper-left quadrant (" << x << " is less than " << this->_midX << " and " << y << " is greater than " << this->_midY);
    this->_ul->getClosestNObjects(x, y, n, objects);
    break;
  case QuadTree<T,S>::Quadrant::LR:
    //Debug("Checking lower-right quadrant (" << x << " is greater than " << this->_midX << " and " << y << " is less than " << this->_midY);
    this->_lr->getClosestNObjects(x, y, n, objects);
    break;
  case QuadTree<T,S>::Quadrant::UR:
    //Debug("Checking upper-right quadrant (" << x << " is greater than " << this->_midX << " and " << y << " is greater than " << this->_midY);
    this->_ur->getClosestNObjects(x, y, n, objects);
    break;
  default:
    break;
  }

  int requiredObjects = n - objects.size();
  if(requiredObjects <= 0) { return; }

  //Debug(requiredObjects << " still required to meet quota of " << n);
  list<T> candidates = this->_objects;
  if(q != QuadTree<T,S>::Quadrant::LL && this->_ll) {
    //Debug("Pulling new candidates from LL");
    this->_ll->getObjects(candidates);
  }
  if(q != QuadTree<T,S>::Quadrant::UL && this->_ul) {
    //Debug("Pulling new candidates from UL");
    this->_ul->getObjects(candidates);
  }
  if(q != QuadTree<T,S>::Quadrant::LR && this->_lr) {
    //Debug("Pulling new candidates from LR");
    this->_lr->getObjects(candidates);
  }
  if(q != QuadTree<T,S>::Quadrant::UR && this->_ur) {
    //Debug("Pulling new candidates from UR");
    this->_ur->getObjects(candidates);
  }

  // Sort the objects in this node by distance to the target point
  PointDistanceComparator<T,S> comparator(x, y);
  candidates.sort(comparator);
  //Debug("Found " << candidates.size() << " potential candidates");

  for(auto object : candidates) {
    //Debug("Adding sorted object at (" << object->getX() << "," << object->getY() << ")");
    objects.push_back(object);
    requiredObjects--;
    if(requiredObjects <= 0) { break; }
  }
}

template <typename T, typename S>
PointDistanceComparator<T,S>::PointDistanceComparator(S x, S y): _x(x), _y(y) {}

template <typename T, typename S>
bool PointDistanceComparator<T,S>::operator()(const T& p1, const T& p2) const {
  return distanceFrom(p1) < distanceFrom(p2);
}

template <typename T, typename S>
S PointDistanceComparator<T,S>::distanceFrom(const T& p) const {
  S xDiff = _x - p->getX();
  S yDiff = _y - p->getY();
  return (xDiff * xDiff) + (yDiff * yDiff);
}

#endif
