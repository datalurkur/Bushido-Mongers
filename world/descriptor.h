#ifndef DESCRIPTOR_H
#define DESCRIPTOR_H

#include <string>
#include <set>

using namespace std;

struct AreaDescriptor {
  string name;

  float openness;
  float density;

  bool isConstructed; // Is this area naturally occurring like a cave, or constructed like a house?
  bool isOutdoors;    // Is this area carved out of a mountain, or erected on a plain?

  // These can either be explicit objects or keywords
  set<string> prominentObjects;  // Objects which tend to occur in fewer numbers at the centers of rooms
  set<string> peripheralObjects; // Objects which tend to occur in greater numbers at the edges of rooms

  float objectDensity;  // A raw reflection of how many objects are in the area
  float objectSparsity; // A granular reflection of how spaced-out objects are in the area (lower means clustered towards the center, higher means spread out evenly)

  AreaDescriptor(const string& name);
};

#endif
