#include "game/bobject.h"
#include "util/assertion.h"

BObject::BObject(ObjectID id, const ProtoBObject& proto): _id(id) {
  list<ObjectExtension::Type>::const_iterator itr;
  for(itr = proto.extensions.begin(); itr != proto.extensions.end(); itr++) {
    addExtension(*itr);
  }
}

BObject::~BObject() {
}

bool BObject::addExtension(ObjectExtension::Type type) {
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

bool BObject::hasExtension(ObjectExtension::Type type) {
  ExtensionMap::iterator itr = _extensions.find(type);
  return(itr != _extensions.end());
}

bool BObject::dropExtension(ObjectExtension::Type type) {
  ExtensionMap::iterator itr = _extensions.find(type);
  if(itr == _extensions.end()) {
    return false;
  } else {
    _extensions.erase(itr);
    delete itr->second;
    return true;
  }
}

ObjectID BObject::getID() const { return _id; }
