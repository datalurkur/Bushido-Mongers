#ifndef MULTICONNECTIONPROVIDER_H
#define MULTICONNECTIONPROVIDER_H

#include "net/connectionbuffer.h"
#include "net/connectionprovider.h"

#include <queue>
using namespace std;

class MultiConnectionProvider: public ConnectionProvider {
public:
  bool recvPacket(Packet &packet);

protected:
  void getAndPrioritizePackets();

protected:
  priority_queue<Packet> _prioritizedPackets;
  ConnectionBufferMap _buffers;
};

#endif
