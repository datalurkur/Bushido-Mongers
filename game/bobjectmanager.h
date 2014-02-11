#ifndef OBJECT_MANAGER_H
#define OBJECT_MANAGER_H

#include "game/bobject.h"
#include "resource/raw.h"

class BObjectManager {
public:
  BObjectManager(const string& rawSet);
  ~BObjectManager();

  BObject* createObject(const string& type);

private:
  template <typename T, typename S>
  BObject* createTypedObject(const ProtoBObject* proto);

private:
  BObjectID _objectCount;
  map<BObjectID, BObject*> _objectMap;

  Raw* _raws;
};

template <typename T, typename S>
BObject* BObjectManager::createTypedObject(const ProtoBObject* proto) {
  BObjectID nextID = _objectCount++;
  return (BObject*) new T(nextID, (S*)proto);
}

#endif
