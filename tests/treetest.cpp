#include "util/log.h"
#include "util/quadtree.h"
#include "util/assertion.h"

#include <set>

using namespace std;

int main() {
  Log::Setup();

  int x = 0, y = 0, mx = 100, my = 100, d = 3;

  Info("Testing quadtree");
  QuadTree<int> tree(x, y, mx, my, d);

  tree.moveObject(1, 5, 10, 10, 15);
  tree.moveObject(2, 10, 15, 20, 25);
  tree.moveObject(3, 50, 50, 60, 60);

  set<int> test;
  tree.findObjects(10, 15, 10, 15, test);

  ASSERT(test.find(1) != test.end(), "Expected to find object 1");
  ASSERT(test.find(2) != test.end(), "Expected to find object 2");
  ASSERT(test.find(3) == test.end(), "Did not expect to find object 3");

  test.clear();
  tree.removeObject(1);
  tree.findObjects(10, 15, 10, 15, test);
  ASSERT(test.find(1) == test.end(), "Expected to find object 1");
  ASSERT(test.find(2) != test.end(), "Expected to find object 2");
  ASSERT(test.find(3) == test.end(), "Did not expect to find object 3");

  Log::Teardown();
  return 0;
}
