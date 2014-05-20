#include "game/complexbobject.h"
#include "game/bobjectmanager.h"

ComplexBObject::ComplexBObject(BObjectManager* manager, BObjectID id, const ProtoComplexBObject* proto): BObject(manager, ComplexType, id, proto) {}

bool ComplexBObject::atCreation() {
  ProtoComplexBObject* p = (ProtoComplexBObject*)_proto;
  if(!BObject::atCreation()) { return false; }
  for(auto componentInfo : p->components) {
    BObject* object = _manager->createObject(componentInfo.second);
    _components[object->getID()] = object;
    _nicknamed[componentInfo.second] = object;
  }
  for(auto connectionInfo : p->connections) {
    BObject* a = _nicknamed[connectionInfo.first];
    auto insertResult = _connections.insert(make_pair(a, ObjectSet()));
    auto itr = insertResult.first;
    for(auto connected : connectionInfo.second) {
      BObject* b = _nicknamed[connected];
      itr->second.insert(b);
    }
  }
  return true;
}

bool ComplexBObject::atDestruction() {
  if(!BObject::atDestruction()) { return false; }
  return true;
}

float ComplexBObject::getWeight() const {
  float total = 0;
  for(auto& componentData : _components) { total += componentData.second->getWeight(); }
  return total;
}
