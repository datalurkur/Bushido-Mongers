#ifndef CONTAINER_H
#define CONTAINER_H

#include "game/containerbase.h"
#include "game/complexbobject.h"

class ProtoContainerBObject : public ProtoComplexBObject {
public:
  ProtoContainerBObject(BObjectType t = ContainerType);
  virtual ~ProtoContainerBObject();

  virtual void pack(SectionedData<ObjectSectionType>& sections) const;
  virtual bool unpack(const SectionedData<ObjectSectionType>& sections);
};

class ContainerBObject : public ContainerBase, public ComplexBObject {
public:
  ContainerBObject(BObjectManager* manager, BObjectID id, const ProtoContainerBObject* proto);
  virtual ~ContainerBObject();

  Area* getArea() const;
  const IVec2& getCoordinates() const;
};

#endif
