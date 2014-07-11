#ifndef BOBJECT_H
#define BOBJECT_H

#include "game/observable.h"
#include "game/bobjectextension.h"
#include "game/bobjecttypes.h"
#include "resource/protobobject.h"
#include "game/combat.h"

#include <map>
#include <list>
using namespace std;

class BObjectManager;
class ContainerBase;

class BObject: virtual public Observable {
public:
  BObject(BObjectManager* manager, BObjectType type, const ProtoBObject* proto);
  virtual ~BObject();

  void assignID(BObjectID id);

  void onChanged();

  // Nomenclature
  const string& getName() const;
  const string& getArchetype() const;

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

  // Generic points of interaction
  virtual DamageResult damage(const Damage& dmg) = 0;

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
