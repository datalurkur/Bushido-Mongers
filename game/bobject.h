#ifndef BOBJECT_H
#define BOBJECT_H

#include "util/propertymap.h"
#include "util/sectioneddata.h"

#include "game/objectextension.h"
#include "game/bobjecttypes.h"

#include <map>
#include <list>

typedef int ObjectID;

class ProtoBObject {
public:
  ProtoBObject(BObjectType t);

  virtual bool pack(void** data, unsigned int& size) const;
  virtual bool unpack(const void* data, unsigned int size);

  BObjectType type;
  list<ExtensionType> extensions;
};

class BObject {
public:
  BObject(BObjectType type, ObjectID id, const ProtoBObject& proto);
  virtual ~BObject();

  // Extension management
  bool addExtension(ExtensionType type);
  bool hasExtension(ExtensionType type);
  bool dropExtension(ExtensionType type);

  // Object attribute accessors
  BObjectType getType() const;
  ObjectID getID() const;

  // Virtual attribute accessors
  virtual float getWeight() const = 0;

private:
  typedef map<ExtensionType, ObjectExtension*> ExtensionMap;
  ExtensionMap _extensions;

  BObjectType _type;
  ObjectID _id;
};

typedef map<ObjectID, BObject*> ObjectMap;

#endif
