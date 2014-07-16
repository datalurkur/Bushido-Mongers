#ifndef RAW_H
#define RAW_H

#include "game/bobject.h"

#include <list>
#include <set>

using namespace std;

#define MAGIC ('b' | ('R' << 8) | ('a' << 16) | ('w' << 24))
#define VERSION 1

struct RawHeader {
  int magic;
  short version;
};

class Raw {
public:
  Raw();
  ~Raw();

  bool pack(ostringstream& str) const;
  bool unpack(istringstream& str);

  unsigned int getNumObjects() const;
  void getObjectNames(list<string>& names) const;

  ProtoBObject* getObject(const string& name) const;
  void getObjectsByKeyword(const string& keyword, list<ProtoBObject*> &objects) const;
  ProtoBObject* getRandomObjectByKeyword(const string& keyword) const;

  bool addObject(const string& name, ProtoBObject* object);
  bool deleteObject(const string& name);

private:
  ProtoBObject* unpackProto(const string& name, const string& objectData);

private:
  typedef map<string, ProtoBObject*> ProtoMap;
  typedef map<string, set<ProtoBObject*> > KeywordMap;
  ProtoMap _objectMap;
  KeywordMap _keywordMap;
};

#endif
