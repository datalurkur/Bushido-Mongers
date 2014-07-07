#ifndef DESCRIPTOR_H
#define DESCRIPTOR_H

struct AreaDescriptor {
  string name;

  bool isConstructed; // Is this area naturally occurring like a cave, or constructed like a house?
  bool isOutdoors;    // Is this area carved out of a mountain, or erected on a plain?

  // These can either be explicit objects or keywords
  list<string> prominentObjects;  // Objects which tend to occur in fewer numbers at the centers of rooms
  list<string> peripheralObjects; // Objects which tend to occur in greater numbers at the edges of rooms

  float objectDensity;  // A raw reflection of how many objects are in the area
  float objectSparsity; // A granular reflection of how spaced-out objects are in the area (lower means clustered towards the center, higher means spread out evenly)

  AreaDescriptor(const string& name);
};

#endif
