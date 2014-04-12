#ifndef CONNECTIONPROVIDER_H
#define CONNECTIONPROVIDER_H

#include "net/packet.h"

class ConnectionProvider {
public:
  virtual bool sendPacket(const NetAddress& dest, const Packet &packet) = 0;
  virtual bool recvPacket(Packet &packet) = 0;
};

#endif
