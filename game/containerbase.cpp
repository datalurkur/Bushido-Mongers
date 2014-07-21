#include "game/containerbase.h"

ContainerBase::ContainerBase() {
}

ContainerBase::~ContainerBase() {
}

bool ContainerBase::addObject(BObjectID object) {
  //Debug("Adding object " << object << " to container");

  auto result = _contents.insert(object);
  if(result.second) {
    //Debug("  -Object successfully added");
    markChanged();
  }

  return result.second;
}

bool ContainerBase::removeObject(BObjectID object) {
  //Debug("Removing object " << object << " from container");

  bool ret = _contents.erase(object);
  if(ret) {
    //Debug("  -Object successfully removed");
    markChanged();
  }

  return ret;
}

const set<BObjectID>& ContainerBase::getContents() const { return _contents; }

void ContainerBase::debugContents() {
  Debug("Container currently contains:");
  for(auto c : _contents) {
    Debug("\t" << c);
  }
}
