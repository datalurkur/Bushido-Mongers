#include "game/complexbobject.h"

ProtoComplexBObject::ProtoComplexBObject(): ProtoBObject(ComplexType) {}
ProtoComplexBObject::~ProtoComplexBObject() {}

bool ProtoComplexBObject::pack(SectionedData<ObjectSectionType>& sections) const {
  if(!ProtoBObject::pack(sections)) { return false; }

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

ComplexBObject::ComplexBObject(BObjectID id, const ProtoComplexBObject* proto): BObject(ComplexType, id, proto) {
  #pragma message "TODO : Use the object manager here to create default components"
}

float ComplexBObject::getWeight() const {
  float total = 0;

  #pragma message "TODO : Cache this value"

  BObjectMap::const_iterator itr;
  for(itr = _components.begin(); itr != _components.end(); itr++) {
    total += itr->second->getWeight();
  }

  return total;
}
