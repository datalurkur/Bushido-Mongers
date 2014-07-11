#ifndef PROTO_BOBJECT_H
#define PROTO_BOBJECT_H

#include "util/propertymap.h"
#include "util/sectioneddata.h"
#include "game/bobjecttypes.h"
#include "resource/protoextension.h"

#include <list>
#include <map>
using namespace std;

class ProtoBObject {
public:
  typedef map<ExtensionType, ProtoBObjectExtension*> ProtoExtensionMap;

public:
  ProtoBObject(const string& name, BObjectType type);
  virtual ~ProtoBObject();

  virtual void pack(SectionedData<ObjectSectionType>& sections) const;
  virtual bool unpack(const SectionedData<ObjectSectionType>& sections);

  string name;
  BObjectType type;
  ProtoExtensionMap extensions;
  list<string> keywords;
};

#endif
