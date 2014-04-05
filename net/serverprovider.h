#ifndef SERVERPROVIDER_H
#define SERVERPROVIDER_H

#include "net/multiconnectionprovider.h"
#include "net/tcpbuffer.h"
#include "net/listensocket.h"

class ServerProvider: public MultiConnectionProvider, public SocketCreationListener {
public:
  ServerProvider(unsigned short localPort = 0);
  virtual ~ServerProvider();

  bool sendPacket(const NetAddress& dest, const Packet &packet);

  unsigned short getLocalPort();

  bool onSocketCreation(const NetAddress& client, TCPSocket *socket);

private:
  ListenSocket *_listenSocket;
};

#endif
