#include "resource/protocomposite.h"

ProtoCompositeBObject::ProtoCompositeBObject(const string& n, BObjectType t): ProtoBObject(n, t) {}
ProtoCompositeBObject::~ProtoCompositeBObject() {}

void ProtoCompositeBObject::pack(SectionedData<ObjectSectionType>& sections) const {
  ProtoBObject::pack(sections);

  SectionedData<AttributeSectionType> compositeData;
  compositeData.addStringListSection(LayersList, layers);

  sections.addSubSections(CompositeData, compositeData);
}

bool ProtoCompositeBObject::unpack(const SectionedData<ObjectSectionType>& sections) {
  if(!ProtoBObject::unpack(sections)) { return false; }

  SectionedData<AttributeSectionType> compositeData;
  if(!sections.getSubSections(CompositeData, compositeData)) { return false; }

  if(!compositeData.getStringListSection(LayersList, layers)) { return false; }

  return true;
}

