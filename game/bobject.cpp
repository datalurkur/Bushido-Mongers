#include "game/bobject.h"
#include "game/containerbase.h"
#include "util/assertion.h"

BObject::BObject(BObjectManager* manager, BObjectType type, const ProtoBObject* proto):
  _manager(manager), _proto(proto), _type(type), _id(0), _keywords(proto->keywords), _location(0) {
  for(auto& pExt : proto->extensions) {
    addExtension(pExt.first, *pExt.second);
  }
}

BObject::~BObject() {
  setLocation(0);
}

void BObject::assignID(BObjectID id) {
  ASSERT(_id == 0, "Object has already been assigned an ID");
  _id = id;
}

// When an object changes, mark its location as having changed (this removes the need for us to check recursively for changes)
void BObject::onChanged() {
  if(_location) {
    _location->markChanged();
  }
}

bool BObject::addExtension(ExtensionType type, const ProtoBObjectExtension& data) {
  ExtensionMap::iterator itr = _extensions.find(type);
  if(itr == _extensions.end()) {
    switch(type) {
    default:
      ASSERT(0, "Attempting to add unhandled extension type " << type);
      break;
    }
    return true;
  } else {
    return false;
  }
}

bool BObject::hasExtension(ExtensionType type) {
  ExtensionMap::iterator itr = _extensions.find(type);
  return(itr != _extensions.end());
}

bool BObject::dropExtension(ExtensionType type) {
  ExtensionMap::iterator itr = _extensions.find(type);
  if(itr == _extensions.end()) {
    return false;
  } else {
    _extensions.erase(itr);
    delete itr->second;
    return true;
  }
}

BObjectType BObject::getType() const { return _type; }
BObjectID BObject::getID() const { return _id; }

void BObject::setLocation(ContainerBase* location) {
  if(_location) {
    _location->removeObject(_id);
  }
  if(location) {
    location->addObject(_id);
  }
  _location = location;
}

ContainerBase* BObject::getLocation() const {
  return _location;
}
