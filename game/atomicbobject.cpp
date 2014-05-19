#include "game/atomicbobject.h"

ProtoAtomicBObject::ProtoAtomicBObject(BObjectType t): ProtoBObject(t), weight(0) {}
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
