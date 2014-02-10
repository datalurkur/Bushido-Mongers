#ifndef ATOMIC_BOBJECT_H
#define ATOMIC_BOBJECT_H

#include "game/bobject.h"
#include "game/bobjecttypes.h"
#include "util/sectioneddata.h"

class ProtoAtomicBObject: public ProtoBObject {
public:
  ProtoAtomicBObject();

  virtual bool pack(SectionedData<AttributeSectionType>& sections) const;
  virtual bool unpack(const SectionedData<AttributeSectionType>& sections);

  float weight;
};

class AtomicBObject : public BObject {
public:
  AtomicBObject(ObjectID id, const ProtoAtomicBObject& proto);

  float getWeight() const;

private:
  float _weight;
};

#endif
