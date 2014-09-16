#ifndef LOCALGAMECLIENT_H
#define LOCALGAMECLIENT_H

#include "io/localfrontend.h"
#include "io/localbackend.h"

class ServerBase;

class LocalGameClient: public LocalFrontEnd, public LocalBackEnd {
public:
  LocalGameClient(ServerBase* server);
  ~LocalGameClient();

  bool isConnected();
};

#endif
