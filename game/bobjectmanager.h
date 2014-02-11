#ifndef OBJECT_MANAGER_H
#define OBJECT_MANAGER_H

#include "game/bobject.h"

class ObjectManager {
public:

private:
  ObjectID _objectCount;
  map<ObjectID, BObject*> _objectMap;
};

#endif
