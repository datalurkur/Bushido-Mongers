#include "util/log.h"
#include "util/boxquadtree.h"
#include "util/pointquadtree.h"

#include <list>

using namespace std;

typedef QuadTreeBoxObject<int> BoxObj;
typedef QuadTreePointObject<int> PointObj;

void setupBox(int x, int y, int mX, int mY, int numObjects, list<BoxObj*>& objects) {
  for(int i = 0; i < numObjects; i++) { 
    int oX = rand() % (mX - x) + x,
        oY = rand() % (mY - y) + y,
        oMX = rand() % (mX - oX) + oX,
        oMY = rand() % (mY - oY) + oY;
    objects.push_back(new BoxObj(oX, oY, oMX, oMY));
    Info("\tAdding object from (" << oX << "," << oY << ") to (" << oMX << "," << oMY << ")");
  }
}

void setupPoint(int x, int y, int mX, int mY, int numObjects, list<PointObj*>& objects) {
  for(int i = 0; i < numObjects; i++) { 
    int oX = rand() % (mX - x) + x,
        oY = rand() % (mY - y) + y;
    objects.push_back(new PointObj(oX, oY));
    Info("\tAdding object at (" << oX << "," << oY << ")");
  }
}

void testBox(int x, int y, int mX, int mY, int d, list<BoxObj*>& objects, int searches) {
  BoxQuadTree<BoxObj*, int>* tree = new BoxQuadTree<BoxObj*, int>(x, y, mX, mY, d, objects);
  for(int i = 0; i < searches; i++) {
    int bX = rand() % (mX - x) + x,
        bY = rand() % (mY - y) + y,
        bmX = rand() % (mX - bX) + bX,
        bmY = rand() % (mY - bY) + bY;
    Info("Finding objects from (" << bX << "," << bY << ") to (" << bmX << "," << bmY << ")");

    list<BoxObj*> bounded;
    tree->getObjects(bX, bY, bmX, bmY, bounded);
    for(auto obj : bounded) {
      Info("\tFound object from (" << obj->getX() << "," << obj->getY() << ") to (" << obj->getMaxX() << "," << obj->getMaxY() << ")");
    }
  }
  delete tree;
}

void testPoint(int x, int y, int mX, int mY, int d, list<PointObj*>& objects, int searches) {
  PointQuadTree<PointObj*, int>* tree = new PointQuadTree<PointObj*, int>(x, y, mX, mY, d, objects);
  for(int i = 0; i < searches; i++) {
    int bX = rand() % (mX - x) + x,
        bY = rand() % (mY - y) + y,
        bmX = rand() % (mX - bX) + bX,
        bmY = rand() % (mY - bY) + bY;
    Info("Finding objects from (" << bX << "," << bY << ") to (" << bmX << "," << bmY << ")");

    list<PointObj*> bounded;
    tree->getObjects(bX, bY, bmX, bmY, bounded);
    for(auto obj : bounded) {
      Info("\tFound object at (" << obj->getX() << "," << obj->getY() << ")");
    }

    bounded.clear();
    int numClosest = rand() % objects.size();
    Info("Finding closest " << numClosest << " objects to (" << bX << "," << bY << ")");
    tree->getClosestNObjects(bX, bY, numClosest, bounded);
    for(auto obj : bounded) {
      Info("\t Found object at (" << obj->getX() << "," << obj->getY() << ")");
    }
  }
  delete tree;
}

void teardownBox(list<BoxObj*>& objects) {
  for(auto object : objects) {
    delete object;
  }
  objects.clear();
}

void teardownPoint(list<PointObj*>& objects) {
  for(auto object : objects) {
    delete object;
  }
  objects.clear();
}

int main() {
  Log::Setup();

  int numObjects = 5;
  int x = 0, y = 0, mx = 10, my = 10, d = 3;

  Info("Testing box quadtree");
  list<BoxObj*> boxObjects;
  setupBox(x, y, mx, my, numObjects, boxObjects);
  testBox(x, y, mx, my, d, boxObjects, 3);
  teardownBox(boxObjects);
  
  Info("Testing point quadtree");
  list<PointObj*> pointObjects;
  setupPoint(x, y, mx, my, numObjects, pointObjects);
  testPoint(x, y, mx, my, d, pointObjects, 3);
  teardownPoint(pointObjects);

  Log::Teardown();
  return 0;
}
