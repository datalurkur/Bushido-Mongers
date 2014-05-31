#ifndef CONTAINER_H
#define CONTAINER_H

#include "game/containerbase.h"
#include "game/complexbobject.h"
#include "resource/protocontainer.h"

class ContainerBObject : public ContainerBase, public ComplexBObject {
public:
  ContainerBObject(BObjectManager* manager, const ProtoContainerBObject* proto);
  virtual ~ContainerBObject();

  Area* getArea() const;
  const IVec2& getCoordinates() const;
};

#endif
