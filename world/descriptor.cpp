#include "world/descriptor.h"

AreaDescriptor::AreaDescriptor(const string& n): name(n) {
  openness = 0.5f;
  density = 0.5f;
  objectDensity = 0.0f;
  objectSparsity = 1.0f;
  isConstructed = false;
  isOutdoors = true;
}
