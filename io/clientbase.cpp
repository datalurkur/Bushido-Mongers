#include "io/clientbase.h"

ClientBase::ClientBase(const string& name): _name(name) {}

ClientBase::~ClientBase() {}

void ClientBase::createCharacter() {
  // In the future, we'll pass config data into this
  CreateCharacterEvent event;
  sendEvent(&event);
}
