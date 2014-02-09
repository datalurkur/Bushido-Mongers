#ifndef RAW_H
#define RAW_H

#include "game/bobject.h"

#include <list>

using namespace std;

#define MAGIC 'b' | ('R' << 8) | ('a' << 16) | ('w' << 24)
#define VERSION 1

struct RawHeader {
  int magic;
  short version;
  unsigned int numObjects;
};

class Raw {
public:
  Raw();
  ~Raw();

  bool unpack(const void* data, unsigned int size);
  bool pack(void** data, unsigned int& size);

  unsigned int getNumObjects() const;
  void getObjectNames(list<string>& names) const;

  ProtoBObject* getObject(const string& name) const;
  bool addObject(const string& name, ProtoBObject* object);
  bool deleteObject(const string& name);
  bool cloneObject(const string& source, const string& dest);

private:
  typedef map<string, ProtoBObject*> ProtoMap;
  ProtoMap _objectMap;
};

#endif
