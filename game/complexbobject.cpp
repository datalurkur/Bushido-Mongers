#include "game/complexbobject.h"
#include "game/bobjectmanager.h"

ComplexBObject::ComplexBObject(BObjectManager* manager, const ProtoComplexBObject* proto): BObject(manager, ComplexType, proto) {
  ProtoComplexBObject* p = (ProtoComplexBObject*)_proto;
  for(auto componentInfo : p->components) {
    BObject* object = _manager->createObjectFromPrototype(componentInfo.second);
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
}

ComplexBObject::~ComplexBObject() {
  for(auto component : _components) {
    _manager->destroyObject(component.second->getID());
  }
}

float ComplexBObject::getWeight() const {
  float total = 0;
  for(auto& componentData : _components) { total += componentData.second->getWeight(); }
  return total;
}

DamageResult ComplexBObject::damage(const Damage& dmg) {
  #pragma message "TODO - Add called shots (where we don't just randomly choose a body part to hit)"
  size_t index = rand() % _components.size();
  auto itr = _components.begin();
  advance(itr, index);
  BObject* target = itr->second;

  DamageResult targetResult = target->damage(dmg);
  if(targetResult.destroyed) {
    #pragma message "TODO - Figure out how to split complex objects if connecting parts are destroyed"
  }
  return targetResult;
}
