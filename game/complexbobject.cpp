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

void ProtoComplexBObject::addComponent(const string& nickname, const string& raw_type) {
  explicitComponents[nickname] = raw_type;
}

void ProtoComplexBObject::addConnection(const string& base, const string& connection) {
  connections[base].insert(connection);
}

void ProtoComplexBObject::remConnection(const string& base, const string& connection) {
  connections[base].erase(connection);
}

void ProtoComplexBObject::getComponents(set<string>& nicknames) {
  for(auto kv : explicitComponents) {
    Debug(kv.first << kv.second);
    nicknames.insert(kv.first);
  }
}

void ProtoComplexBObject::getConnectionsFromComponent(const string& nickname, set<string>& nicknames) {
  for(auto connection : connections[nickname]) {
    nicknames.insert(connection);
  }
}

string ProtoComplexBObject::typeOfComponent(const string& nickname) {
  return explicitComponents[nickname];
}

ComplexBObject::ComplexBObject(BObjectManager* manager, BObjectID id, const ProtoComplexBObject* proto): BObject(manager, ComplexType, id, proto) {}

bool ComplexBObject::atCreation() {
  if(!BObject::atCreation()) { return false; }
  #pragma message "TODO : Use the object manager here to create default components"

  _manager;
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
