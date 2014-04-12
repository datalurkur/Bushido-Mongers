#include "game/bobjectcontainer.h"

BObjectContainer::BObjectContainer(): _parent(0) {
}

BObjectContainer::~BObjectContainer() {
  if(_parent) {
    // Attempt to spill this container's contents into its parent container
    for(auto objectID : _contents) {
      #pragma message "This won't work because the object still thinks it's here"
      //_parent->addObject(objectID);
    }
  }
  _contents.clear();
}

void BObjectContainer::setParent(BObjectContainer* parent) { _parent = parent; }

bool BObjectContainer::addObject(BObjectID object) {
  Debug("Adding object " << object << " to container");

  auto result = _contents.insert(object);
  if(result.second) { markChanged(); }

  return result.second;
}

bool BObjectContainer::removeObject(BObjectID object) {
  Debug("Removing object " << object << " from container");

  bool ret = _contents.erase(object);
  if(ret) { markChanged(); }

  return ret;
}

const set<BObjectID>& BObjectContainer::getContents() const { return _contents; }

void BObjectContainer::debugContents() {
  Debug("Container currently contains:");
  for(auto c : _contents) {
    Debug("\t" << c);
  }
}

Area* BObjectContainer::getArea() const {
  ASSERT(_parent, "Container must have a parent for its area to be accessible");
  return _parent->getArea();
}

const IVec2& BObjectContainer::getCoordinates() const {
  ASSERT(_parent, "Container must have a parent for its coordinates to be accessible");
  return _parent->getCoordinates();
}
