#include "io/serverbase.h"
#include "io/gameevent.h"

ServerBase::ServerBase(const string& rawSet) {
  // In the future, we'll just pass a config file in here
  // The config file will dictate whether a world is generated or loaded, and what the details of generation are

  _core = new GameCore();
  setup(rawSet);
}

ServerBase::~ServerBase() {
  delete _core;
}

void ServerBase::setup(const string& rawSet) {
  _core->generateWorld(rawSet, 10);
}

void ServerBase::start() { _core->start(); }
void ServerBase::stop() { _core->stop(); }

bool ServerBase::assignClient(ClientBase* client, const string& name) {
  _lock.lock();
  auto existingClient = _assignedClients.find(name);
  if(existingClient != _assignedClients.end()) {
    return false;
  }
  _assignedClients[name] = client;
  _assignedNames[client] = name;
  _lock.unlock();
  return true;
}

void ServerBase::removeClient(ClientBase* client) {
  map<string, ClientBase*>::iterator itr;
  _lock.lock();
  for(itr = _assignedClients.begin(); itr != _assignedClients.end(); itr++) {
    if(itr->second == client) { break; }
  }
  if(itr != _assignedClients.end()) {
    _assignedClients.erase(itr);
  }
  _assignedNames.erase(client);
  _lock.unlock();
}

void ServerBase::clientEvent(ClientBase* client, const GameEvent* event) {
  auto clientName = _assignedNames.find(client);
  if(clientName == _assignedNames.end()) {
    #pragma message "We should hang up on any client that does this"
    Error("Unassigned client attempting to send data to the server");
    return;
  }
  Debug("Received client event from " << clientName->second);

  switch(event->type) {
  case GameEventType::CreateCharacter:
    Info("Creating character for " << clientName->second);
    break;
  default:
    Warn("Unhandled game event type " << event->type);
    break;
  }
}
