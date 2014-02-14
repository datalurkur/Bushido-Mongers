#include "game/compositebobject.h"

ProtoCompositeBObject::ProtoCompositeBObject(): ProtoBObject(CompositeType) {}
ProtoCompositeBObject::~ProtoCompositeBObject() {}

void ProtoCompositeBObject::pack(SectionedData<ObjectSectionType>& sections) const {
  ProtoBObject::pack(sections);

  SectionedData<AttributeSectionType> compositeData;
  #pragma message "TODO : Pack layer data here"

  sections.addSubSections(CompositeData, compositeData);
}

bool ProtoCompositeBObject::unpack(const SectionedData<ObjectSectionType>& sections) {
  if(!ProtoBObject::unpack(sections)) { return false; }

  SectionedData<AttributeSectionType> compositeData;
  if(!sections.getSubSections(CompositeData, compositeData)) { return false; }

  #pragma message "TODO : Parse layer data here"

  return true;
}

CompositeBObject::CompositeBObject(BObjectID id, const ProtoCompositeBObject* proto): BObject(CompositeType, id, proto) {
  #pragma message "TODO : Use the object manager here to create default components"
  #pragma message "TODO : Enforce that layers are only ever atomic types"
}

float CompositeBObject::getWeight() const {
  float total = 0;

  #pragma message "TODO : Cache this value"

  BObjectList::const_iterator itr;
  for(itr = _layers.begin(); itr != _layers.end(); itr++) {
    total += (*itr)->getWeight();
  }

  return total;
}
