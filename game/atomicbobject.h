#ifndef ATOMIC_BOBJECT_H
#define ATOMIC_BOBJECT_H

#include "game/bobject.h"

class ProtoAtomicBObject: public ProtoBObject {
public:
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
