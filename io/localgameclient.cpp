#include "io/localgameclient.h"

LocalGameClient::LocalGameClient(ServerBase* server): LocalFrontEnd(server) {
}

LocalGameClient::~LocalGameClient() {
  disconnectSender();
}
