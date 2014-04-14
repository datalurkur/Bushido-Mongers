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
  _components[nickname] = raw_type;
}

void ProtoComplexBObject::remComponent(const string& nickname) {
  _components.erase(nickname);
  for(auto connection : _connections) {
    if(connection.first == nickname || connection.second == nickname) {
      _connections.erase(connection);
    }
  }
}

void ProtoComplexBObject::addConnection(const StringPair& connection) {
  _connections.insert(connection);
}

void ProtoComplexBObject::remConnection(const StringPair& connection) {
  _connections.erase(connection);
}

void ProtoComplexBObject::getComponents(set<string>& nicknames) {
  for(auto kv : _components) {
    nicknames.insert(kv.first);
  }
}

void ProtoComplexBObject::getConnections(set<StringPair>& connections) {
  for(auto connection : _connections) {
    connections.insert(connection);
  }
}

void ProtoComplexBObject::getConnectionsOfComponent(const string& nickname, set<string>& nicknames) {
  for(auto connection : _connections) {
    if(connection.first == nickname) {
      nicknames.insert(connection.second);
    } else if(connection.second == nickname) {
      nicknames.insert(connection.first);
    }
  }
}

string ProtoComplexBObject::typeOfComponent(const string& nickname) {
  return _components[nickname];
}

bool ProtoComplexBObject::hasComponent(const string& nickname) {
  for(auto kv : _components) {
    if(kv.first == nickname) {
      return true;
    }
  }
  return false;
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
