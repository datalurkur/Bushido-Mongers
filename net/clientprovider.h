#ifndef CLIENTPROVIDER_H
#define CLIENTPROVIDER_H

#include "net/multiconnectionprovider.h"
#include "net/tcpbuffer.h"

class ClientProvider: public MultiConnectionProvider {
public:
  ~ClientProvider();

  bool sendPacket(const Packet &packet);
};

#endif
