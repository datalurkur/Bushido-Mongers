#ifndef BOBJECT_H
#define BOBJECT_H

#include "game/observable.h"
#include "game/bobjectextension.h"
#include "game/bobjecttypes.h"
#include "resource/protobobject.h"

#include <map>
#include <list>
using namespace std;

typedef int BObjectID;

class BObjectManager;
class ContainerBase;

class BObject: virtual public Observable {
public:
  BObject(BObjectManager* manager, BObjectType type, BObjectID id, const ProtoBObject* proto);
  virtual ~BObject();

  virtual bool atCreation();
  virtual bool atDestruction();

  // Extension management
  bool addExtension(ExtensionType type, const ProtoBObjectExtension& data);
  bool hasExtension(ExtensionType type);
  bool dropExtension(ExtensionType type);

  // Object attribute accessors
  BObjectType getType() const;
  BObjectID getID() const;

  // Virtual attribute accessors
  virtual float getWeight() const = 0;

  // Location management
  void setLocation(ContainerBase* location);
  ContainerBase* getLocation() const;

protected:
  BObjectManager* _manager;

  typedef map<ExtensionType, BObjectExtension*> ExtensionMap;
  ExtensionMap _extensions;

  const ProtoBObject* _proto;

  BObjectType _type;
  BObjectID _id;
  list<string> _keywords;

  ContainerBase* _location;
};

typedef list<BObject*> BObjectList;
typedef map<BObjectID, BObject*> BObjectMap;

#endif
