#ifndef BOBJECT_H
#define BOBJECT_H

#include "util/propertymap.h"
#include "util/sectioneddata.h"

#include "game/bobjectextension.h"
#include "game/bobjecttypes.h"

#include <map>
#include <list>

typedef int BObjectID;

class ProtoBObject {
public:
  typedef map<ExtensionType, ProtoBObjectExtension*> ProtoExtensionMap;

public:
  ProtoBObject(BObjectType t);

  virtual bool pack(SectionedData<ObjectSectionType>& sections) const;
  virtual bool unpack(const SectionedData<ObjectSectionType>& sections);

  BObjectType type;
  ProtoExtensionMap extensions;
};

class BObject {
public:
  BObject(BObjectType type, BObjectID id, const ProtoBObject* proto);
  virtual ~BObject();

  // Extension management
  bool addExtension(ExtensionType type, const ProtoBObjectExtension& data);
  bool hasExtension(ExtensionType type);
  bool dropExtension(ExtensionType type);

  // Object attribute accessors
  BObjectType getType() const;
  BObjectID getID() const;

  // Virtual attribute accessors
  virtual float getWeight() const = 0;

private:
  typedef map<ExtensionType, BObjectExtension*> ExtensionMap;
  ExtensionMap _extensions;

  BObjectType _type;
  BObjectID _id;
};

typedef map<BObjectID, BObject*> BObjectMap;

#endif
