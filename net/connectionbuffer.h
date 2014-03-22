#ifndef CONNECTIONBUFFER_H
#define CONNECTIONBUFFER_H

#include "net/packet.h"

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
  virtual void doInboundBuffering() = 0;
  virtual void doOutboundBuffering() = 0;

  // Determine how many packets are buffered before they start being dropped
  void setMaxBufferSize(unsigned int maxPackets);
  unsigned int getMaxBufferSize();

  // Determine the maximum packet size
  void setMaxPacketSize(unsigned int maxSize);
  unsigned int getMaxPacketSize();

  // TODO - Write bandwidth limiting code

  // Returns false if the packet queue is full
  bool providePacket(const Packet &packet);
  // Returns false if there are no packets to consume
  bool consumePacket(Packet &packet);

  unsigned short getLocalPort() const;

  // DEBUG
  void logStatistics();

protected:
  Socket *_socket;

  static unsigned int DefaultMaxBufferSize;
  static unsigned int DefaultMaxPacketSize;

  // Why SDL decided to capitalize Thread and not mutex escapes me
  mutex *_inboundQueueLock, *_outboundQueueLock, *_inboundLock, *_outboundLock;
  thread *_inboundThread, *_outboundThread;
  bool _inboundShouldDie, _outboundShouldDie;

  char *_packetBuffer;

  typedef queue<Packet> PacketQueue;
  PacketQueue _inbound;
  PacketQueue _outbound;

  unsigned int _maxBufferSize;
  unsigned int _maxPacketSize;

  // Statistics
  unsigned int _droppedPackets;

  unsigned int _receivedPackets;
  unsigned int _sentPackets;

  unsigned int _inboundPackets;
  unsigned int _outboundPackets;
};

typedef map<NetAddress,ConnectionBuffer*> ConnectionBufferMap;

#endif
