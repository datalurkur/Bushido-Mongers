#include "resource/protocomplex.h"

ProtoComplexBObject::ProtoComplexBObject(const string& n, BObjectType t): ProtoBObject(n, t) {}
ProtoComplexBObject::~ProtoComplexBObject() {}

void ProtoComplexBObject::pack(SectionedData<ObjectSectionType>& sections) const {
  ProtoBObject::pack(sections);

  SectionedData<AttributeSectionType> complexData;

  // Pack the component map
  SectionedData<string> componentMap;
  for(auto component : components) {
    componentMap.addSection(component.first, component.second.c_str(), component.second.size() + 1);
  }
  complexData.addSubSections(ComponentMap, componentMap);

  // Pack the connection map
  SectionedData<string> connectionMap;
  for(auto connection : connections) {
    list<string> connectedObjects;
    for(auto connectedObject : connection.second) {
      connectedObjects.push_back(connectedObject);
    }
    connectionMap.addStringListSection(connection.first, connectedObjects);
  }
  complexData.addSubSections(ConnectionMap, connectionMap);

  sections.addSubSections(ComplexData, complexData);
}

bool ProtoComplexBObject::unpack(const SectionedData<ObjectSectionType>& sections) {
  if(!ProtoBObject::unpack(sections)) { return false; }

  SectionedData<AttributeSectionType> complexData;
  if(!sections.getSubSections(ComplexData, complexData)) { return false; }

  // Unpack the component map
  SectionedData<string> componentMap;
  if(!complexData.getSubSections(ComponentMap, componentMap)) { return false; }
  for(auto component : componentMap) {
    components.insert(make_pair(component.first, string((char*)component.second.data)));
  }

  // Unpack the connection list
  SectionedData<string> connectionMap;
  if(!complexData.getSubSections(ConnectionMap, connectionMap)) { return false; }
  for(auto connection : connectionMap) {
    list<string> connectionData;
    if(!connectionMap.getStringListSection(connection.first, connectionData)) { return false; }

    connections.insert(make_pair(connection.first, set<string>()));
    for(auto connectedObject : connectionData) {
      connections[connection.first].insert(connectedObject);
    }
  }

  return true;
}

void ProtoComplexBObject::addComponent(const string& nickname, const string& raw_type) {
  components[nickname] = raw_type;
}

void ProtoComplexBObject::remComponent(const string& nickname) {
  components.erase(nickname);
  connections.erase(nickname);
  for(auto connection : connections) {
    connection.second.erase(nickname);
  }
}

void ProtoComplexBObject::remConnection(const string& first, const string& second) {
  auto fItr = connections.find(first);
  if(fItr == connections.end()) {
    connections.insert(make_pair(first, set<string>()));
  }
  connections[first].insert(second);
  auto sItr = connections.find(second);
  if(sItr == connections.end()) {
    connections.insert(make_pair(second, set<string>()));
  }
  connections[second].insert(first);
}

void ProtoComplexBObject::addConnection(const string& first, const string& second) {
  auto fItr = connections.find(first),
       sItr = connections.find(second);
  if(fItr != connections.end()) {
    fItr->second.erase(second);
  }
  if(sItr != connections.end()) {
    sItr->second.erase(first);
  }
}

bool ProtoComplexBObject::hasComponent(const string& nickname) {
  auto itr = components.find(nickname);
  return (itr != components.end());
}

