#ifndef PROTO_CONTAINER_H
#define PROTO_CONTAINER_H

#include "resource/protocomplex.h"

class ProtoContainerBObject : public ProtoComplexBObject {
public:
  ProtoContainerBObject(BObjectType t = ContainerType);
  virtual ~ProtoContainerBObject();

  virtual void pack(SectionedData<ObjectSectionType>& sections) const;
  virtual bool unpack(const SectionedData<ObjectSectionType>& sections);
};

#endif
