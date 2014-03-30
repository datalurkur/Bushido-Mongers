#include "game/bobjectcontainer.h"

BObjectContainer::BObjectContainer(): _parent(0) {}

BObjectContainer::~BObjectContainer() {
  if(_parent) {
    // Attempt to spill this container's contents into its parent container
    for(auto objectID : _contents) {
      _parent->addObject(objectID);
    }
  }
  _contents.clear();
}

void BObjectContainer::setParent(BObjectContainer* parent) { _parent = parent; }

bool BObjectContainer::addObject(BObjectID object) {
  auto result = _contents.insert(object);
  return result.second;
}

bool BObjectContainer::removeObject(BObjectID object) {
  return (_contents.erase(object) == 1);
}
