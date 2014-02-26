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
  virtual ~ProtoBObject();

  virtual void pack(SectionedData<ObjectSectionType>& sections) const;
  virtual bool unpack(const SectionedData<ObjectSectionType>& sections);

  BObjectType type;
  ProtoExtensionMap extensions;
  list<string> keywords;
};

class BObjectManager;

class BObject {
public:
  BObject(BObjectType type, BObjectID id, const ProtoBObject* proto);
  virtual ~BObject();

  virtual bool atCreation(BObjectManager* manager);
  virtual void atDestruction(BObjectManager* manager);

  // Extension management
  bool addExtension(ExtensionType type, const ProtoBObjectExtension& data);
  bool hasExtension(ExtensionType type);
  bool dropExtension(ExtensionType type);

  // Object attribute accessors
  BObjectType getType() const;
  BObjectID getID() const;

  // Virtual attribute accessors
  virtual float getWeight() const = 0;

protected:
  typedef map<ExtensionType, BObjectExtension*> ExtensionMap;
  ExtensionMap _extensions;

  const ProtoBObject* _proto;

  BObjectType _type;
  BObjectID _id;
  list<string> _keywords;
};

typedef list<BObject*> BObjectList;
typedef map<BObjectID, BObject*> BObjectMap;

#endif