#ifndef COMPLEX_BOBJECT_H
#define COMPLEX_BOBJECT_H

#include "util/sectioneddata.h"

#include "game/bobject.h"
#include "game/bobjecttypes.h"

#include <set>
#include <map>

class ProtoComplexBObject : public ProtoBObject {
public:
  ProtoComplexBObject();
  virtual ~ProtoComplexBObject();

  virtual void pack(SectionedData<ObjectSectionType>& sections) const;
  virtual bool unpack(const SectionedData<ObjectSectionType>& sections);

  map<string,string> explicitComponents;
  map<string,string> keywordComponents;
  map<string,string> connections;
};

class ComplexBObject : public BObject {
public:
  typedef map<string, BObject*> NicknameMap;
  typedef set<BObject*> ObjectSet;
  typedef map<BObject*, ObjectSet> ConnectivityMap;

public:
  ComplexBObject(BObjectID id, const ProtoComplexBObject* proto);

  virtual bool atCreation(BObjectManager* manager);
  virtual void atDestruction(BObjectManager* manager);

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
