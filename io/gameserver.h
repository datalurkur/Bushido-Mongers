#ifndef GAME_SERVER_H
#define GAME_SERVER_H

#include "io/serverbase.h"
#include "io/remoteclientstub.h"
#include "net/listensocket.h"

class GameServer: public ServerBase, public SocketCreationListener {
public:
  GameServer(const string& rawSet, unsigned short listenPort);
  virtual ~GameServer();

  bool onSocketCreation(const NetAddress &client, TCPSocket *socket);

private:
  ListenSocket _listenSocket;

  list<RemoteClientStub*> _remoteClients;
};

#endif
