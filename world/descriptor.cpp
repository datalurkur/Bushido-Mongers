#include "world/descriptor.h"

AreaDescriptor::AreaDescriptor(const string& n): name(n) {
  objectDensity = 0.0f;
  objectSparsity = 1.0f;
  isConstructed = false;
  isOutdoors = true;
}
