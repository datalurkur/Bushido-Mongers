#ifndef BOXQUADTREE_H
#define BOXQUADTREE_H

#include "util/quadtree.h"

template <typename T, typename S>
class BoxQuadTree : public QuadTree<T,S> {
public:
  BoxQuadTree(S x, S y, S maxX, S maxY, unsigned int maxDepth, const list<T>& sourceObjects, unsigned int depth = 1);

  void getObjects(S x, S y, S maxX, S maxY, list<T>& objects);
};

template <typename T, typename S>
BoxQuadTree<T,S>::BoxQuadTree(S x, S y, S maxX, S maxY, unsigned int maxDepth, const list<T>& sourceObjects, unsigned int depth): QuadTree<T,S>(x, y, maxX, maxY) {
  if(depth == 1) {
    for(auto object : sourceObjects) {
      if(object->getX()    < this->_x ||
         object->getY()    < this->_y ||
         object->getMaxX() > this->_maxX ||
         object->getMaxY() > this->_maxY
      ) {
        throw ObjectOutOfBoundsException();
      }
    }
  }
  auto numObjects = sourceObjects.size();
  if(depth < maxDepth && numObjects > 0) {
    Debug("At depth " << depth + 1);

    // Collect all of the objects' midpoints
    vector<S> xValues(numObjects);
    vector<S> yValues(numObjects);
    int i = 0;
    for(auto object : sourceObjects) {
      xValues[i] = object->getMidX();
      yValues[i] = object->getMidY();
      i++;
    }
    // Compute the median of the objects' midpoints
    auto medianObject = numObjects / 2;
    nth_element(xValues.begin(), xValues.begin() + medianObject, xValues.end());
    nth_element(yValues.begin(), yValues.begin() + medianObject, yValues.end());
    this->_midX = xValues[medianObject];
    this->_midY = yValues[medianObject];
    Debug("Median value of objects found to be " << this->_midX << "," << this->_midY);

    // Partition the objects
    list<T> unusedObjects;
    list<T> llObjects, lrObjects, ulObjects, urObjects;
    for(auto object : sourceObjects) {
      if(object->getX() < this->_midX) {
        if(object->getY() < this->_midY) {
          // Lower-left quadrant
          if(object->getMaxX() <= this->_midX && object->getMaxY() <= this->_midY) {
            Debug("Object at (" << object->getX() << "," << object->getY() << ") to (" << object->getMaxX() << "," << object->getMaxY() << ") pushed into lower-left quadrant");
            llObjects.push_back(object);
            continue;
          }
        } else {
          // Upper-left quadrant
          if(object->getMaxX() <= this->_midX) {
            Debug("Object at (" << object->getX() << "," << object->getY() << ") to (" << object->getMaxX() << "," << object->getMaxY() << ") pushed into upper-left quadrant");
            ulObjects.push_back(object);
            continue;
          }
        }
      } else {
        if(object->getY() < this->_midY) {
          // Lower-right quadrant
          if(object->getMaxY() <= this->_midY) {
            Debug("Object at (" << object->getX() << "," << object->getY() << ") to (" << object->getMaxX() << "," << object->getMaxY() << ") pushed into lower-right quadrant");
            lrObjects.push_back(object);
            continue;
          }
        } else {
          // Upper-right quadrant
            Debug("Object at (" << object->getX() << "," << object->getY() << ") to (" << object->getMaxX() << "," << object->getMaxY() << ") pushed into upper-right quadrant");
          urObjects.push_back(object);
          continue;
        }
      }
      Debug("Object at (" << object->getX() << "," << object->getY() << ") to (" << object->getMaxX() << "," << object->getMaxY() << ") pushed flat onto node");
      unusedObjects.push_back(object);
    }

    // Create the quads
    this->_ll = new BoxQuadTree<T,S>(this->_x,    this->_y,    this->_midX, this->_midY, maxDepth, llObjects, depth + 1);
    this->_lr = new BoxQuadTree<T,S>(this->_midX, this->_y,    this->_maxX, this->_midY, maxDepth, lrObjects, depth + 1);
    this->_ul = new BoxQuadTree<T,S>(this->_x,    this->_midY, this->_midX, this->_maxY, maxDepth, ulObjects, depth + 1);
    this->_ur = new BoxQuadTree<T,S>(this->_midX, this->_midY, this->_maxX, this->_maxY, maxDepth, urObjects, depth + 1);

    // Consume the remaining objects
    this->_objects = unusedObjects;
  } else if(numObjects > 0) {
    // This is a leaf node, consume all of the objects
    this->_objects = sourceObjects;
  }
}

template <typename T, typename S>
void BoxQuadTree<T,S>::getObjects(S x, S y, S maxX, S maxY, list<T>& objects) {
  for(auto object : this->_objects) {
    if(object->getX() > maxX || object->getY() > maxY || object->getMaxX() < x || object->getMaxY() < y) { continue; }
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

#endif
