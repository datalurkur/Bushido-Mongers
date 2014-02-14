#include "game/bobjectmanager.h"
#include "game/atomicbobject.h"
#include "game/compositebobject.h"
#include "game/complexbobject.h"

#include "util/filesystem.h"

BObjectManager::BObjectManager(const string& rawSet) {
  _raws = new Raw();
  list<string> raws;
  FileSystem::GetDirectoryContentsRecursive(rawSet, raws);
  list<string>::iterator itr;
  for(itr = raws.begin(); itr != raws.end(); itr++) {
    Info("Loading raw data from " << *itr);
    void* data;
    unsigned int dataSize;
    dataSize = FileSystem::GetFileData(*itr, &data);
    if(dataSize == 0) {
      Error("Failed to read data from " << *itr);
      continue;
    }
    if(!_raws->unpack(data, dataSize)) {
      Error("Failed to load data from " << *itr);
    }
    free(data);
  }
}

BObjectManager::~BObjectManager() {
  delete _raws;
}

BObject* BObjectManager::createObject(const string& type) {
  ProtoBObject* proto = _raws->getObject(type);
  if(!proto) {
    Error("Object type " << type << " not found in object prototypes");
    return 0;
  }
  
  switch(proto->type) {
  case AtomicType:
    return createTypedObject<AtomicBObject, ProtoAtomicBObject>(proto);
  case CompositeType:
    return createTypedObject<CompositeBObject, ProtoCompositeBObject>(proto);
  case ComplexType:
    return createTypedObject<ComplexBObject, ProtoComplexBObject>(proto);
  default:
    Error("Object creation not implemented for object type " << proto->type);
    return 0;
  }
}
