#include "resource/protobobject.h"

ProtoBObject::ProtoBObject(const string& n, BObjectType t): name(n), type(t) {}
ProtoBObject::~ProtoBObject() {}

void ProtoBObject::pack(SectionedData<ObjectSectionType>& sections) const {
  // Construct the base data sections
  SectionedData<AttributeSectionType> baseSections;
  baseSections.addStringListSection(KeywordsList, keywords);

  // Add the base data
  sections.addSubSections(BaseData, baseSections);

  // Construct the extension sections
  SectionedData<ExtensionType> extensionSections;
  for(auto& extensionData : extensions) {
    SectionedData<AttributeSectionType> extensionAttributes;
    extensionData.second->pack(extensionAttributes);
    extensionSections.addSubSections(extensionData.first, extensionAttributes);
  }

  // Add the extension data
  sections.addSubSections(ExtensionData, extensionSections);
}

bool ProtoBObject::unpack(const SectionedData<ObjectSectionType>& sections) {
  // Unpack base data
  SectionedData<AttributeSectionType> baseSections;
  if(!sections.getSubSections(BaseData, baseSections)) {
    Error("Failed to unpack base data");
    return false;
  }

  // Parse base data
  if(!baseSections.getStringListSection(KeywordsList, keywords)) {
    Error("Failed to unpack keywords data");
    return false;
  }

  // Unpack extension data
  SectionedData<ExtensionType> extensionSections;
  if(!sections.getSubSections(ExtensionData, extensionSections)) {
    Error("Failed to unpack extension data");
    return false;
  }

  // Parse extension data
  for(auto& extensionData : extensionSections) {
    ProtoBObjectExtension* extension;
    switch(extensionData.first) {
    default:
      Error("Unpacking of extension type " << extensionData.first << " is not supported");
      return false;
    }
    SectionedData<AttributeSectionType> extensionAttributes;
    extensionAttributes.unpack(extensionData.second.data, extensionData.second.size);
    if(!extension->unpack(extensionAttributes)) {
      Error("Failed to unpack extension");
      return false;
    }
    extensions[extensionData.first] = extension;
  }

  return true;
}
