#include "io/remotegameclient.h"

RemoteGameClient::RemoteGameClient(const NetAddress& addr): RemoteFrontEnd(addr) {
}

RemoteGameClient::~RemoteGameClient() {
  disconnectSender();
}
