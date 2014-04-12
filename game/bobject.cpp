#include "game/bobject.h"
#include "game/bobjectcontainer.h"
#include "util/assertion.h"

ProtoBObject::ProtoBObject(BObjectType t): type(t) {}
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

BObject::BObject(BObjectManager* manager, BObjectType type, BObjectID id, const ProtoBObject* proto):
  _manager(manager), _proto(proto), _type(type), _id(id), _keywords(proto->keywords), _location(0) {
  for(auto& pExt : proto->extensions) {
    addExtension(pExt.first, *pExt.second);
  }
}

BObject::~BObject() {
  setLocation(0);
}

bool BObject::atCreation() {
  return true;
}
bool BObject::atDestruction() {
  return true;
}

bool BObject::addExtension(ExtensionType type, const ProtoBObjectExtension& data) {
  ExtensionMap::iterator itr = _extensions.find(type);
  if(itr == _extensions.end()) {
    switch(type) {
    default:
      ASSERT(0, "Attempting to add unhandled extension type " << type);
      break;
    }
    return true;
  } else {
    return false;
  }
}

bool BObject::hasExtension(ExtensionType type) {
  ExtensionMap::iterator itr = _extensions.find(type);
  return(itr != _extensions.end());
}

bool BObject::dropExtension(ExtensionType type) {
  ExtensionMap::iterator itr = _extensions.find(type);
  if(itr == _extensions.end()) {
    return false;
  } else {
    _extensions.erase(itr);
    delete itr->second;
    return true;
  }
}

BObjectType BObject::getType() const { return _type; }
BObjectID BObject::getID() const { return _id; }

void BObject::setLocation(BObjectContainer* location) {
  if(_location) {
    _location->removeObject(_id);
  }
  if(location) {
    location->addObject(_id);
  }
  _location = location;
}

BObjectContainer* BObject::getLocation() const {
  return _location;
}
