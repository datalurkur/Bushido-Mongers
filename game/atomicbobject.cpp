#include "game/atomicbobject.h"

ProtoAtomicBObject::ProtoAtomicBObject(): ProtoBObject(AtomicType) {}

bool ProtoAtomicBObject::pack(SectionedData<AttributeSectionType>& sections) const {
  if(!ProtoBObject::pack(sections)) { return false; }

  return sections.addSection<float>(WeightAttribute, weight);
}

bool ProtoAtomicBObject::unpack(const SectionedData<AttributeSectionType>& sections) {
  if(!ProtoBObject::unpack(sections)) { return false; }

  if(!sections.getSection<float>(WeightAttribute, weight)) {
    Error("Weight data not present");
    return false;
  }
  return true;
}

AtomicBObject::AtomicBObject(ObjectID id, const ProtoAtomicBObject& proto): BObject(AtomicType, id, proto) {
  _weight = proto.weight;
}

float AtomicBObject::getWeight() const { return _weight; }
