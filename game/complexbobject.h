#ifndef COMPLEX_BOBJECT_H
#define COMPLEX_BOBJECT_H

#include "game/bobject.h"
#include "resource/protocomplex.h"

class ComplexBObject : public BObject {
public:
  typedef map<string, BObject*> NicknameMap;
  typedef set<BObject*> ObjectSet;
  typedef map<BObject*, ObjectSet> ConnectivityMap;

public:
  ComplexBObject(BObjectManager* manager, BObjectID id, const ProtoComplexBObject* proto);

  virtual bool atCreation();
  virtual bool atDestruction();

  float getWeight() const;

private:
  // Map by ID
  BObjectMap _components;
  // Map by nickname
  NicknameMap _nicknamed;
  // Object connections
  ConnectivityMap _connections;
};

#endif
