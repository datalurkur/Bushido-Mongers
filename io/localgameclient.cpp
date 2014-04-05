#include "io/localgameclient.h"
#include "io/gameserver.h"

LocalGameClient::LocalGameClient(GameServer* server, const string& name): ClientBase(name), _server(server) {
}

LocalGameClient::~LocalGameClient() {
}

void LocalGameClient::sendEvent(const GameEvent* event) {
  _server->clientEvent(this, event);
}

bool LocalGameClient::connect() {
  return _server->assignClient(this, _name);
}

void LocalGameClient::disconnect() {
  _server->removeClient(this);
}
