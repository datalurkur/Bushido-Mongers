#ifndef BOBJECT_CONTAINER_H
#define BOBJECT_CONTAINER_H

#include "game/bobject.h"
#include "util/vector.h"

#include <set>

using namespace std;

class Area;

class BObjectContainer {
public:
  BObjectContainer();
  virtual ~BObjectContainer();

  virtual Area* getArea() const;
  virtual const IVec2& getCoordinates() const;

  void setParent(BObjectContainer* parent);

protected:
  friend class BObject;

  bool addObject(BObjectID object);
  bool removeObject(BObjectID object);

private:
  void debugContents();

private:
  BObjectContainer* _parent;
  set<BObjectID> _contents;
};

#endif
