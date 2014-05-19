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
    teardownObject(itr.second);
  }
  _objectMap.clear();
  delete _raws;
}

BObject* BObjectManager::createObject(const string& type) {
  ProtoBObject* proto = _raws->getObject(type);
  if(!proto) {
    // Check keywords
    proto = _raws->getRandomObjectByKeyword(type);

    if(!proto) {
      Error("Object type " << type << " not found in object prototypes or keywords");
      return 0;
    }
  }

  switch(proto->type) {
  case AtomicType:
    return createTypedObject<AtomicBObject, ProtoAtomicBObject>(proto);
  case CompositeType:
    return createTypedObject<CompositeBObject, ProtoCompositeBObject>(proto);
  case ComplexType:
    return createTypedObject<ComplexBObject, ProtoComplexBObject>(proto);
  case ContainerType:
    return createTypedObject<ContainerBObject, ProtoContainerBObject>(proto);
  default:
    Error("Object creation not implemented for object type " << proto->type);
    return 0;
  }
}

void BObjectManager::destroyObject(BObjectID id) {
  BObjectMap::iterator itr = _objectMap.find(id);
  if(itr == _objectMap.end()) {
    Error("Object " << id << " not found");
    return;
  }

  teardownObject(itr->second);

  _objectMap.erase(itr);
}

void BObjectManager::teardownObject(BObject* object) {
  if(!object->atDestruction()) {
    Error("Object " << object->getID() << " failed to tear down properly");
  }
  delete object;
}

BObject* BObjectManager::getObject(BObjectID id) {
  BObjectMap::iterator itr = _objectMap.find(id);
  if(itr == _objectMap.end()) {
    Error("Object " << id << " not found");
    return 0;
  }
  return itr->second;
}
