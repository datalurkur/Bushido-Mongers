#include "io/localgameclient.h"

LocalGameClient::LocalGameClient(ServerBase* server): LocalFrontEnd(server) {
}

LocalGameClient::~LocalGameClient() {
  disconnectSender();
}

bool LocalGameClient::isConnected() {
  return true;
}
