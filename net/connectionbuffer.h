#ifndef CONNECTIONBUFFER_H
#define CONNECTIONBUFFER_H

#include "net/packet.h"

#include <atomic>
#include <mutex>
#include <thread>
#include <queue>
#include <map>
using namespace std;

class ConnectionBuffer {
public:
  ConnectionBuffer();
  virtual ~ConnectionBuffer();

  void startBuffering();
  void stopBuffering();

  // Determine how many packets are buffered before they start being dropped
  void setMaxBufferSize(unsigned int maxPackets);
  unsigned int getMaxBufferSize();

  // Determine the maximum packet size
  void setMaxPacketSize(unsigned int maxSize);
  unsigned int getMaxPacketSize();

  // Returns false if the packet queue is full
  bool providePacket(const Packet& packet);
  // Returns false if there are no packets to consume
  bool consumePacket(Packet& packet);
  // Blocks caller thread until a packet is available, then returns
  void consumePacketBlocking(Packet& packet);

  unsigned short getLocalPort() const;

  // DEBUG
  void logStatistics();

protected:
  virtual void doInboundBuffering() = 0;
  virtual void doOutboundBuffering() = 0;

protected:
  Socket *_socket;

  static unsigned int DefaultMaxBufferSize;
  static unsigned int DefaultMaxPacketSize;

  mutex _inboundQueueLock, _outboundQueueLock;
  thread _inboundThread, _outboundThread;
  atomic<bool> _inboundShouldDie, _outboundShouldDie;

  char *_packetBuffer;

  typedef queue<Packet> PacketQueue;
  PacketQueue _inbound;
  PacketQueue _outbound;

  unsigned int _maxBufferSize;
  unsigned int _maxPacketSize;

  // Statistics
  atomic<unsigned int> _droppedPackets;

  atomic<unsigned int> _receivedPackets;
  atomic<unsigned int> _sentPackets;

  atomic<unsigned int> _inboundPackets;
  atomic<unsigned int> _outboundPackets;
};

typedef map<NetAddress,ConnectionBuffer*> ConnectionBufferMap;

#endif
