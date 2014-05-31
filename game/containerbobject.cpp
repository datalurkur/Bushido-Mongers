#include "game/containerbobject.h"
#include "game/bobjectmanager.h"

ContainerBObject::ContainerBObject(BObjectManager* manager, const ProtoContainerBObject* proto): ComplexBObject(manager, proto) {
}
  #pragma message "TODO - Add container setup"

ContainerBObject::~ContainerBObject() {
  list<BObject*> objectsToRelocate;
  for(auto objectID : _contents) {
    // Attempt to spill this container's contents into its parent container
    BObject* object = _manager->getObject(objectID);
    objectsToRelocate.push_back(object);
  }
  ContainerBase* parentContainer = getLocation();
  for(auto object : objectsToRelocate) {
    // We never set an object's location specifically by adding it to another container's contents (or removing it from this container)
    // We use its setLocation method, which takes care of both sides to keep movement clean
    object->setLocation(parentContainer);
  }
  if(_contents.size() > 0) {
    Error("Failed to cleanly tear down container - content objects' destructors will be called implicitly, rather than being destroyed by the object manager");
  }
}

Area* ContainerBObject::getArea() const {
  return getLocation()->getArea();
}

const IVec2& ContainerBObject::getCoordinates() const {
  return getLocation()->getCoordinates();
}
