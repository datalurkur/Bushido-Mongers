#include "game/atomicbobject.h"

ProtoAtomicBObject::ProtoAtomicBObject(): ProtoBObject(AtomicType) {}

bool ProtoAtomicBObject::pack(void** data, unsigned int& size) const {
}

bool ProtoAtomicBObject::unpack(const void* data, unsigned int size) {
}

AtomicBObject::AtomicBObject(ObjectID id, const ProtoAtomicBObject& proto): BObject(AtomicType, id, proto) {
  _weight = proto.weight;
}

float AtomicBObject::getWeight() const { return _weight; }
