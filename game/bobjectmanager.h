#ifndef OBJECT_MANAGER_H
#define OBJECT_MANAGER_H

#include "game/bobject.h"
#include "resource/raw.h"

class BObjectManager {
public:
  BObjectManager(const string& rawSet);
  ~BObjectManager();

  BObject* createObject(const string& type);
  void destroyObject(BObjectID id);

  BObject* getObject(BObjectID id);

private:
  template <typename T, typename S>
  BObject* createTypedObject(const ProtoBObject* proto);

private:
  BObjectID _objectCount;
  BObjectMap _objectMap;

  Raw* _raws;
};

template <typename T, typename S>
BObject* BObjectManager::createTypedObject(const ProtoBObject* proto) {
  BObjectID nextID = ++_objectCount;
  BObject* newObject = (BObject*) new T(this, nextID, (S*)proto);
  _objectMap[nextID] = newObject;

  if(!newObject->atCreation()) {
    delete newObject;
    _objectMap.erase(nextID);
    return 0;
  } else {
    return newObject;
  }
}

#endif
