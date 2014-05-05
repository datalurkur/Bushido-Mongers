#include "io/clientbase.h"
#include "io/gameevent.h"

ClientBase::ClientBase() {}

ClientBase::~ClientBase() {}

void ClientBase::createCharacter(const string& name) {
  // TODO - pass config data into this
  CreateCharacterEvent event(name);
  sendToServer(&event);
}

void ClientBase::loadCharacter(BObjectID id) {
  LoadCharacterEvent event(id);
  sendToServer(&event);
}

void ClientBase::unloadCharacter() {
  UnloadCharacterEvent event;
  sendToServer(&event);
}

void ClientBase::moveCharacter(const IVec2& dir) {
  MoveCharacterEvent event(dir);
  sendToServer(&event);
}
