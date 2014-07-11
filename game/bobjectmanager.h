#ifndef OBJECT_MANAGER_H
#define OBJECT_MANAGER_H

#include "game/bobject.h"
#include "resource/raw.h"

class BObjectManager {
public:
  BObjectManager(const string& rawSet);
  ~BObjectManager();

  BObject* createObjectFromPrototype(const string& type);
  void destroyObject(BObjectID id);
  void addObject(BObject* object);

  BObject* getObject(BObjectID id);

  Raw* getRaws() const;

private:
  BObjectID _objectCount;
  BObjectMap _objectMap;

  Raw* _raws;
};

#endif
