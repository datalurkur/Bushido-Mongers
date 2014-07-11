#ifndef PROTO_COMPOSITE_H
#define PROTO_COMPOSITE_H

#include "resource/protobobject.h"

class ProtoCompositeBObject : public ProtoBObject {
public:
  ProtoCompositeBObject(const string& name, BObjectType t = CompositeType);
  virtual ~ProtoCompositeBObject();

  virtual void pack(SectionedData<ObjectSectionType>& sections) const;
  virtual bool unpack(const SectionedData<ObjectSectionType>& sections);

  list<string> layers;
};

#endif
