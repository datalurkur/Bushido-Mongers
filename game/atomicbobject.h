#ifndef ATOMIC_BOBJECT_H
#define ATOMIC_BOBJECT_H

#include "game/bobject.h"
#include "resource/protoatomic.h"

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
