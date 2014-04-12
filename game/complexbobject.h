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

  void addComponent(const string& nickname, const string& raw_type);
  void addConnection(const string& base, const string& connection);
  void remConnection(const string& base, const string& connection);

  void getComponents(set<string>& nicknames);
  void getConnectionsFromComponent(const string& nickname, set<string>& connections);

  string typeOfComponent(const string& nickname);

  map<string,string> explicitComponents;
  map<string,string> keywordComponents;
  map<string,set<string>> connections;
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
