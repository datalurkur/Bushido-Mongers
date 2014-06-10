#include "io/remoteclientstub.h"

RemoteClientStub::RemoteClientStub(ServerBase* server, TCPSocket* socket): LocalFrontEnd(server), RemoteBackEnd(socket) {
}

RemoteClientStub::~RemoteClientStub() {
}
