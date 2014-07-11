#ifndef PROTO_CONTAINER_H
#define PROTO_CONTAINER_H

#include "resource/protocomplex.h"

class ProtoContainerBObject : public ProtoComplexBObject {
public:
  ProtoContainerBObject(const string& name, BObjectType t = ContainerType);
  virtual ~ProtoContainerBObject();

  virtual void pack(SectionedData<ObjectSectionType>& sections) const;
  virtual bool unpack(const SectionedData<ObjectSectionType>& sections);
};

#endif
