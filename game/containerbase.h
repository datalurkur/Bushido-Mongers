#ifndef CONTAINER_BASE_H
#define CONTAINER_BASE_H

#include "game/bobject.h"
#include "util/vector.h"

#include <set>

using namespace std;

class Area;

class ContainerBase: virtual public Observable {
public:
  ContainerBase();
  virtual ~ContainerBase();

  virtual Area* getArea() const = 0;
  virtual const IVec2& getCoordinates() const = 0;

  const set<BObjectID>& getContents() const;

protected:
  friend class BObject;
  friend class LocalBackEnd;

  bool addObject(BObjectID object);
  bool removeObject(BObjectID object);

  void debugContents();

protected:
  set<BObjectID> _contents;
};

#endif
