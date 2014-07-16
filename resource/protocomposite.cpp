#include "resource/protocomposite.h"

ProtoCompositeBObject::ProtoCompositeBObject(const string& n, BObjectType t): ProtoBObject(n, t) {}
ProtoCompositeBObject::~ProtoCompositeBObject() {}

void ProtoCompositeBObject::pack(SectionedData<ObjectSectionType>& sections) const {
  ProtoBObject::pack(sections);

  SectionedData<AttributeSectionType> compositeData;
  compositeData.addSection(LayersList, layers);

  sections.addSection(CompositeData, compositeData);
}

bool ProtoCompositeBObject::unpack(const SectionedData<ObjectSectionType>& sections) {
  if(!ProtoBObject::unpack(sections)) { return false; }

  SectionedData<AttributeSectionType> compositeData;
  if(!sections.getSection(CompositeData, compositeData)) { return false; }

  if(!compositeData.getSection(LayersList, layers)) { return false; }

  return true;
}

