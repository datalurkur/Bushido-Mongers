#include "io/localfrontend.h"
#include "io/serverbase.h"

LocalFrontEnd::LocalFrontEnd(ServerBase* server, const string& name): _server(server), _name(name) {}
LocalFrontEnd::~LocalFrontEnd() {}

bool LocalFrontEnd::connectSender() {
  return _server->assignClient(this, _name);
}

void LocalFrontEnd::disconnectSender() {
  _server->removeClient(this);
}

void LocalFrontEnd::sendToServer(GameEvent* event) {
  _server->clientEvent(this, event);
}
