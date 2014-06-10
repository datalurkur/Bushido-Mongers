#ifndef REMOTE_CLIENT_STUB_H
#define REMOTE_CLIENT_STUB_H

#include "io/localfrontend.h"
#include "io/remotebackend.h"

class RemoteClientStub: public LocalFrontEnd, public RemoteBackEnd {
public:
  RemoteClientStub(ServerBase* server, TCPSocket* socket);
  ~RemoteClientStub();
};

#endif
