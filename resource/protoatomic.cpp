#include "resource/protoatomic.h"

ProtoAtomicBObject::ProtoAtomicBObject(const string& n, BObjectType t): ProtoBObject(n, t), weight(0) {}
ProtoAtomicBObject::~ProtoAtomicBObject() {}

void ProtoAtomicBObject::pack(SectionedData<ObjectSectionType>& sections) const {
  ProtoBObject::pack(sections);

  SectionedData<AttributeSectionType> atomicData;
  atomicData.addSection<float>(WeightAttribute, weight);
  sections.addSection(AtomicData, atomicData);
}

bool ProtoAtomicBObject::unpack(const SectionedData<ObjectSectionType>& sections) {
  if(!ProtoBObject::unpack(sections)) { return false; }

  SectionedData<AttributeSectionType> atomicData;
  if(!sections.getSection(AtomicData, atomicData)) { return false; }

  if(!atomicData.getSection<float>(WeightAttribute, weight)) {
    Error("Weight data not present");
    return false;
  }

  return true;
}

