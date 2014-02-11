#ifndef COMPLEX_BOBJECT_H
#define COMPLEX_BOBJECT_H

#include "util/sectioneddata.h"

#include "game/bobject.h"
#include "game/bobjecttypes.h"
#include "game/container.h"

class ProtoComplexBObject : public ProtoBObject {
public:
  ProtoComplexBObject();

  virtual bool pack(SectionedData<ObjectSectionType>& sections) const;
  virtual bool unpack(const SectionedData<ObjectSectionType>& sections);

  // Who knows what this is going to be
  //list<string> components;
};

class ComplexBObject : public BObject {
public:
  ComplexBObject(BObjectID id, const ProtoComplexBObject* proto);

  float getWeight() const;

private:
  BObjectMap _components;
};

#endif
