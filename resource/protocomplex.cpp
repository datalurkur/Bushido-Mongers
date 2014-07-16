#include "resource/protocomplex.h"

ProtoComplexBObject::ProtoComplexBObject(const string& n, BObjectType t): ProtoBObject(n, t) {}
ProtoComplexBObject::~ProtoComplexBObject() {}

void ProtoComplexBObject::pack(SectionedData<ObjectSectionType>& sections) const {
  ProtoBObject::pack(sections);

  SectionedData<AttributeSectionType> complexData;

  // Pack the component map
  SectionedData<string> componentMap;
  for(auto component : components) {
    componentMap.addSection(component.first, component.second);
  }
  complexData.addSection(ComponentMap, componentMap);

  // Pack the connection map
  SectionedData<string> connectionMap;
  for(auto connection : connections) {
    list<string> connectedObjects;
    for(auto connectedObject : connection.second) {
      connectedObjects.push_back(connectedObject);
    }
    connectionMap.addSection(connection.first, connectedObjects);
  }
  complexData.addSection(ConnectionMap, connectionMap);

  sections.addSection(ComplexData, complexData);
}

bool ProtoComplexBObject::unpack(const SectionedData<ObjectSectionType>& sections) {
  if(!ProtoBObject::unpack(sections)) { return false; }

  SectionedData<AttributeSectionType> complexData;
  if(!sections.getSection(ComplexData, complexData)) { return false; }

  // Unpack the component map
  SectionedData<string> componentMap;
  if(!complexData.getSection(ComponentMap, componentMap)) { return false; }
  for(auto component : componentMap) {
    string componentData;
    componentMap.getSection(component.first, componentData);
    components.insert(make_pair(component.first, componentData));
  }

  // Unpack the connection list
  SectionedData<string> connectionMap;
  if(!complexData.getSection(ConnectionMap, connectionMap)) { return false; }
  for(auto connection : connectionMap) {
    list<string> connectionData;
    if(!connectionMap.getSection(connection.first, connectionData)) { return false; }

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

