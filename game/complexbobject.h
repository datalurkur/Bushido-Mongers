#ifndef COMPLEX_BOBJECT_H
#define COMPLEX_BOBJECT_H

#include "util/sectioneddata.h"
#include "util/uniquestringpair.h"

#include "game/bobject.h"
#include "game/bobjecttypes.h"

#include <utility>
#include <set>
#include <map>

class ProtoComplexBObject : public ProtoBObject {
public:
  ProtoComplexBObject(BObjectType t = ComplexType);
  virtual ~ProtoComplexBObject();

  virtual void pack(SectionedData<ObjectSectionType>& sections) const;
  virtual bool unpack(const SectionedData<ObjectSectionType>& sections);

  void addComponent(const string& nickname, const string& raw_type);
  void remComponent(const string& nickname);

  void addConnection(const string& first, const string& second);
  void remConnection(const string& first, const string& second);

  void getUniqueConnections(set<UniqueStringPair>& results);

  bool hasComponent(const string& nickname);

  map<string,string> components;
  map<string,set<string> > connections;
};

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
