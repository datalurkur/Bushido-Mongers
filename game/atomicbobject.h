#ifndef ATOMIC_BOBJECT_H
#define ATOMIC_BOBJECT_H

#include "game/bobject.h"
#include "game/bobjecttypes.h"
#include "util/sectioneddata.h"

class ProtoAtomicBObject: public ProtoBObject {
public:
  ProtoAtomicBObject(BObjectType t = AtomicType);
  virtual ~ProtoAtomicBObject();

  virtual void pack(SectionedData<ObjectSectionType>& sections) const;
  virtual bool unpack(const SectionedData<ObjectSectionType>& sections);

  float weight;
};

class AtomicBObject : public BObject {
public:
  AtomicBObject(BObjectManager* manager, BObjectID id, const ProtoAtomicBObject* proto);

  virtual bool atCreation();
  virtual bool atDestruction();

  float getWeight() const;

private:
  float _weight;
};

#endif
