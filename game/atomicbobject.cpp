#include "game/atomicbobject.h"

AtomicBObject::AtomicBObject(BObjectManager* manager, const ProtoAtomicBObject* proto): BObject(manager, AtomicType, proto), _integrity(1.0f) {
  _weight = proto->weight;
}

AtomicBObject::~AtomicBObject() {
}

float AtomicBObject::getWeight() const { return _weight; }

DamageResult AtomicBObject::damage(const Damage& dmg) {
  DamageResult result;

  _integrity -= (dmg.amount / _weight);
  if(_integrity <= 0) {
    result.remaining = -(_integrity * _weight);
    result.absorbed = dmg.amount - result.remaining;
    result.destroyed = true;
  } else {
    result.absorbed  = dmg.amount;
    result.remaining = 0;
    result.destroyed = false;
  }

  return result;
}
