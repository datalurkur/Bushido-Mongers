#include "game/bobjectmanager.h"
#include "game/atomicbobject.h"
#include "game/compositebobject.h"
#include "game/complexbobject.h"
#include "game/containerbobject.h"

#include "util/filesystem.h"

BObjectManager::BObjectManager(const string& rawSet): _objectCount(0) {
  _raws = new Raw();
  list<string> raws;
  FileSystem::GetDirectoryContentsRecursive(rawSet, raws);
  for(string rawName : raws) {
    Info("Loading raw data from " << rawName);
    void* data;
    unsigned int dataSize;
    dataSize = FileSystem::GetFileData(rawName, &data);
    if(dataSize == 0) {
      Error("Failed to read data from " << rawName);
      continue;
    }
    if(!_raws->unpack(data, dataSize)) {
      Error("Failed to load data from " << rawName);
    }
    free(data);
  }
}

BObjectManager::~BObjectManager() {
  for(auto itr : _objectMap) {
    delete itr.second;
  }
  _objectMap.clear();
  delete _raws;
}

BObject* BObjectManager::createObjectFromPrototype(const string& type) {
  ProtoBObject* proto = _raws->getObject(type);
  if(!proto) {
    // Check keywords
    proto = _raws->getRandomObjectByKeyword(type);

    if(!proto) {
      Error("Object type " << type << " not found in object prototypes or keywords");
      return 0;
    }
  }

  BObject* newObject = 0;
  switch(proto->type) {
  case AtomicType:
    newObject = (BObject*)new AtomicBObject(this, (ProtoAtomicBObject*)proto);
    break;
  case CompositeType:
    newObject = (BObject*)new CompositeBObject(this, (ProtoCompositeBObject*)proto);
    break;
  case ComplexType:
    newObject = (BObject*)new ComplexBObject(this, (ProtoComplexBObject*)proto);
    break;
  case ContainerType:
    newObject = (BObject*)new ContainerBObject(this, (ProtoContainerBObject*)proto);
    break;
  default:
    Error("Object creation not implemented for object type " << proto->type);
    return 0;
  }
  addObject(newObject);
  return newObject;
}

void BObjectManager::destroyObject(BObjectID id) {
  BObjectMap::iterator itr = _objectMap.find(id);
  if(itr == _objectMap.end()) {
    Error("Object " << id << " not found");
    return;
  }

  delete itr->second;
  _objectMap.erase(itr);
}

void BObjectManager::addObject(BObject* object) {
  BObjectID nextID = ++_objectCount;
  _objectMap[nextID] = object;
  object->assignID(nextID);
}

BObject* BObjectManager::getObject(BObjectID id) {
  BObjectMap::iterator itr = _objectMap.find(id);
  if(itr == _objectMap.end()) {
    Error("Object " << id << " not found");
    return 0;
  }
  return itr->second;
}
