#include "game/atomicbobject.h"

ProtoAtomicBObject::ProtoAtomicBObject(): ProtoBObject(AtomicType), weight(0) {}
ProtoAtomicBObject::~ProtoAtomicBObject() {}

void ProtoAtomicBObject::pack(SectionedData<ObjectSectionType>& sections) const {
  ProtoBObject::pack(sections);

  SectionedData<AttributeSectionType> atomicData;
  atomicData.addSection<float>(WeightAttribute, weight);
  sections.addSubSections(AtomicData, atomicData);
}

bool ProtoAtomicBObject::unpack(const SectionedData<ObjectSectionType>& sections) {
  if(!ProtoBObject::unpack(sections)) { return false; }

  SectionedData<AttributeSectionType> atomicData;
  if(!sections.getSubSections(AtomicData, atomicData)) { return false; }

  if(!atomicData.getSection<float>(WeightAttribute, weight)) {
    Error("Weight data not present");
    return false;
  }

  return true;
}

AtomicBObject::AtomicBObject(BObjectID id, const ProtoAtomicBObject* proto): BObject(AtomicType, id, proto) {
  _weight = proto->weight;
}

float AtomicBObject::getWeight() const { return _weight; }
