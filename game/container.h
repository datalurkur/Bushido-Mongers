#ifndef CONTAINER_H
#define CONTAINER_H

#include "game/containerbase.h"
#include "game/complexbobject.h"

class Container : public ContainerBase, public ComplexBObject {
public:
  Container(BObjectManager* manager, BObjectID id, const ProtoComplexBObject* proto);
  virtual ~Container();

  Area* getArea() const;
  const IVec2& getCoordinates() const;
};

#endif
