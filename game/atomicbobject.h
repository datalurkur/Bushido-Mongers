#ifndef ATOMIC_BOBJECT_H
#define ATOMIC_BOBJECT_H

#include "game/bobject.h"
#include "resource/protoatomic.h"

class AtomicBObject : public BObject {
public:
  AtomicBObject(BObjectManager* manager, const ProtoAtomicBObject* proto);
  ~AtomicBObject();

  float getWeight() const;

  virtual DamageResult damage(const Damage& dmg);

private:
  float _weight;
  float _integrity;
};

#endif
