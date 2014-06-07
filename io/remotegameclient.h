#ifndef REMOTEGAMECLIENT_H
#define REMOTEGAMECLIENT_H

#include "io/localbackend.h"
#include "io/remotefrontend.h"

class RemoteGameClient: public LocalBackEnd, public RemoteFrontEnd {
public:
  RemoteGameClient(const NetAddress& addr, const string& name);
  ~RemoteGameClient();

private:
};

#endif
