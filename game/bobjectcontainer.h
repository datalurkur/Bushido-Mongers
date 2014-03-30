#ifndef BOBJECT_CONTAINER_H
#define BOBJECT_CONTAINER_H

#include "game/bobject.h"

#include <set>

using namespace std;

class BObjectContainer {
public:
  BObjectContainer();
  ~BObjectContainer();

  void setParent(BObjectContainer* parent);

protected:
  friend class BObject;

  bool addObject(BObjectID object);
  bool removeObject(BObjectID object);

private:
  BObjectContainer* _parent;
  set<BObjectID> _contents;
};

#endif
