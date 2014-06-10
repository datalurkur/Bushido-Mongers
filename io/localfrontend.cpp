#include "io/localfrontend.h"
#include "io/serverbase.h"

LocalFrontEnd::LocalFrontEnd(ServerBase* server): _server(server) {}
LocalFrontEnd::~LocalFrontEnd() {}

bool LocalFrontEnd::connectSender(const string& name) {
  return _server->assignClient(this, name);
}

void LocalFrontEnd::disconnectSender() {
  _server->removeClient(this);
}

void LocalFrontEnd::sendToServer(GameEvent* event) {
  _server->clientEvent(this, event);
}

