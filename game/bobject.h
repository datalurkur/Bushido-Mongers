#ifndef BOBJECT_H
#define BOBJECT_H

#include "util/propertymap.h"
#include "game/objectextension.h"

#include <list>
#include <map>

typedef int ObjectID;

class ProtoBObject {
public:
  list<ObjectExtension::Type> extensions;
};

class BObject {
public:
  BObject(ObjectID id, const ProtoBObject& proto);
  ~BObject();

  // Extension management
  bool addExtension(ObjectExtension::Type type);
  bool hasExtension(ObjectExtension::Type type);
  bool dropExtension(ObjectExtension::Type type);

  // Object attribute accessors
  ObjectID getID() const;

  // Virtual attribute accessors
  virtual float getWeight() const = 0;

private:
  typedef map<ObjectExtension::Type, ObjectExtension*> ExtensionMap;
  ExtensionMap _extensions;

  ObjectID _id;
};

typedef map<ObjectID, BObject*> ObjectMap;

#endif
