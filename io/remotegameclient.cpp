#include "io/remotegameclient.h"

RemoteGameClient::RemoteGameClient(const NetAddress& addr, const string& name): RemoteFrontEnd(addr, name) {
}

RemoteGameClient::~RemoteGameClient() {
  disconnectSender();
}
