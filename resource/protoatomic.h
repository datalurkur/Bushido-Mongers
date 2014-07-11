#ifndef PROTO_ATOMIC_H
#define PROTO_ATOMIC_H

#include "resource/protobobject.h"

class ProtoAtomicBObject: public ProtoBObject {
public:
  ProtoAtomicBObject(const string& name, BObjectType t = AtomicType);
  virtual ~ProtoAtomicBObject();

  virtual void pack(SectionedData<ObjectSectionType>& sections) const;
  virtual bool unpack(const SectionedData<ObjectSectionType>& sections);

  float weight;
};

#endif
