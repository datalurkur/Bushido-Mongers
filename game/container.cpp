#include "game/container.h"
#include "util/assertion.h"

Container::Container() {
}

Container::~Container() {
  ASSERT(0, "Container being torn down without any handling of object destruction");
}

bool Container::addContent(BObject* object) {
  BObjectMap::iterator itr = _contents.find(object->getID());
  if(itr == _contents.end()) {
    _contents[object->getID()] = object;
    return true;
  } else {
    return false;
  }
}

bool Container::removeContent(BObject* object) {
  BObjectMap::iterator itr = _contents.find(object->getID());
  if(itr == _contents.end()) {
    return false;
  } else {
    _contents.erase(itr);
    return true;
  }
}
