#include "game/bobject.h"
#include "util/assertion.h"

ProtoBObject::ProtoBObject(BObjectType t): type(t) {}
ProtoBObject::~ProtoBObject() {}

bool ProtoBObject::pack(SectionedData<ObjectSectionType>& sections) const {
  // Construct the base data sections
  SectionedData<AttributeSectionType> baseSections;
  // Since we don't currently pack any information as part of the base data, this is basically a no-op

  // Add the base data
  if(!sections.addSubSections(BaseData, baseSections)) { return false; }

  // Construct the extension sections
  SectionedData<ExtensionType> extensionSections;
  ProtoExtensionMap::const_iterator itr;
  for(itr = extensions.begin(); itr != extensions.end(); itr++) {
    SectionedData<AttributeSectionType> extensionAttributes;
    if(!itr->second->pack(extensionAttributes)) { return false; }
    extensionSections.addSubSections(itr->first, extensionAttributes);
  }

  // Add the extension data
  if(!sections.addSubSections(ExtensionData, extensionSections)) { return false; }

  return true;
}

bool ProtoBObject::unpack(const SectionedData<ObjectSectionType>& sections) {
  // Unpack base data
  SectionedData<AttributeSectionType> baseSections;
  if(!sections.getSubSections(BaseData, baseSections)) {
    Error("Failed to unpack base data");
    return false;
  }

  // Parse base data
  // Nothing to do here

  // Unpack extension data
  SectionedData<ExtensionType> extensionSections;
  if(!sections.getSubSections(ExtensionData, extensionSections)) {
    Error("Failed to unpack extension data");
    return false;
  }

  // Parse extension data
  SectionedData<ExtensionType>::iterator itr;
  for(itr = extensionSections.begin(); itr != extensionSections.end(); itr++) {
    ProtoBObjectExtension* extension;
    switch(itr->first) {
    default:
      Error("Unpacking of extension type " << itr->first << " is not supported");
      return false;
    }
    SectionedData<AttributeSectionType> extensionAttributes;
    if(!extensionAttributes.unpack(itr->second.data, itr->second.size)) {
      Error("Failed to unpack extension");
      return false;
    }
    if(!extension->unpack(extensionAttributes)) {
      Error("Failed to unpack extension");
      return false;
    }
    extensions[itr->first] = extension;
  }

  return true;
}

BObject::BObject(BObjectType type, BObjectID id, const ProtoBObject* proto): _type(type), _id(id) {
  ProtoBObject::ProtoExtensionMap::const_iterator itr;
  for(itr = proto->extensions.begin(); itr != proto->extensions.end(); itr++) {
    addExtension(itr->first, *itr->second);
  }
}

BObject::~BObject() {
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
