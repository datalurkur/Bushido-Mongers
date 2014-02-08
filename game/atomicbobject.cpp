#include "game/atomicbobject.h"

AtomicBObject::AtomicBObject(ObjectID id, const ProtoAtomicBObject& proto): BObject(id, proto) {
  _weight = proto.weight;
}

float AtomicBObject::getWeight() const { return _weight; }
