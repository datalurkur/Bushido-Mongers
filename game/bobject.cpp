#include "game/bobject.h"
#include "util/assertion.h"

ProtoBObject::ProtoBObject(BObjectType t): type(t) {}

bool ProtoBObject::pack(void** data, unsigned int& size) const {
}

bool ProtoBObject::unpack(const void* data, unsigned int size) {
}

BObject::BObject(BObjectType type, ObjectID id, const ProtoBObject& proto): _type(type), _id(id) {
  list<ExtensionType>::const_iterator itr;
  for(itr = proto.extensions.begin(); itr != proto.extensions.end(); itr++) {
    addExtension(*itr);
  }
}

BObject::~BObject() {
}

bool BObject::addExtension(ExtensionType type) {
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
ObjectID BObject::getID() const { return _id; }
