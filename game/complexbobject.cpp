#include "game/complexbobject.h"

ProtoComplexBObject::ProtoComplexBObject(): ProtoBObject(ComplexType) {}
ProtoComplexBObject::~ProtoComplexBObject() {}

void ProtoComplexBObject::pack(SectionedData<ObjectSectionType>& sections) const {
  ProtoBObject::pack(sections);

  SectionedData<AttributeSectionType> complexData;
  #pragma message "TODO : Pack contents data here"

  return sections.addSubSections(ComplexData, complexData);
}

bool ProtoComplexBObject::unpack(const SectionedData<ObjectSectionType>& sections) {
  if(!ProtoBObject::unpack(sections)) { return false; }

  SectionedData<AttributeSectionType> complexData;
  if(!sections.getSubSections(ComplexData, complexData)) { return false; }

  #pragma message "TODO : Parse contents data here"

  return true;
}

ComplexBObject::ComplexBObject(BObjectManager* manager, BObjectID id, const ProtoComplexBObject* proto): BObject(manager, ComplexType, id, proto) {}

bool ComplexBObject::atCreation() {
  if(!BObject::atCreation()) { return false; }
  #pragma message "TODO : Use the object manager here to create default components"
  return true;
}

bool ComplexBObject::atDestruction() {
  if(!BObject::atDestruction()) { return false; }
  return true;
}

float ComplexBObject::getWeight() const {
  float total = 0;

  for(auto& componentData : _components) { total += componentData.second->getWeight(); }
  #pragma message "TODO : Cache this value"

  return total;
}
