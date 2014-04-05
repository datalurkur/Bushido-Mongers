#include "io/clientbase.h"
#include "io/gameevent.h"

ClientBase::ClientBase() {}

ClientBase::~ClientBase() {}

void ClientBase::createCharacter(const string& name) {
  // In the future, we'll pass config data into this
  CreateCharacterEvent event(name);
  sendEvent(&event);
}

void ClientBase::loadCharacter(BObjectID id) {
  LoadCharacterEvent event(id);
  sendEvent(&event);
}

void ClientBase::unloadCharacter() {
  UnloadCharacterEvent event;
  sendEvent(&event);
}
