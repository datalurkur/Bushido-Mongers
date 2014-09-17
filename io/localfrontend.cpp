#include "io/localfrontend.h"
#include "io/serverbase.h"

LocalFrontEnd::LocalFrontEnd(ServerBase* server): _server(server) {}
LocalFrontEnd::~LocalFrontEnd() {}

bool LocalFrontEnd::connectSender(const string& name) {
  return _server->assignClient(this, name);
}

void LocalFrontEnd::disconnectSender() {
  //_server->removeClient(this);
}

bool LocalFrontEnd::sendToServer(EventQueue* queue) {
  for(auto e : *queue) {
    _server->clientEvent(this, e);
  }
  return true;
}

bool LocalFrontEnd::sendToServer(GameEvent* event) {
  _server->clientEvent(this, event);
  delete event;
  return true;
}
