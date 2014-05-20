#include "game/atomicbobject.h"

AtomicBObject::AtomicBObject(BObjectManager* manager, BObjectID id, const ProtoAtomicBObject* proto): BObject(manager, AtomicType, id, proto) {
  _weight = proto->weight;
}

bool AtomicBObject::atCreation() {
  if(!BObject::atCreation()) { return false; }
  return true;
}
bool AtomicBObject::atDestruction() {
  if(!BObject::atDestruction()) { return false; }
  return true;
}

float AtomicBObject::getWeight() const { return _weight; }
