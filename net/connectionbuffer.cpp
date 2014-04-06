#include "net/connectionbuffer.h"
#include "util/assertion.h"
#include "util/log.h"

unsigned int ConnectionBuffer::DefaultMaxBufferSize = 5096;

unsigned int ConnectionBuffer::DefaultMaxPacketSize = 1024;

ConnectionBuffer::ConnectionBuffer():
  _socket(0), _packetBuffer(0), _maxBufferSize(DefaultMaxBufferSize), _maxPacketSize(DefaultMaxPacketSize),
  _droppedPackets(0), _receivedPackets(0), _sentPackets(0), _inboundPackets(0), _outboundPackets(0)
{
}

ConnectionBuffer::~ConnectionBuffer() {
  ASSERT(!_inboundThread.joinable() && !_outboundThread.joinable(), "Threads still active");
}

void ConnectionBuffer::startBuffering() {
  if(!_inboundThread.joinable()) {
    _inboundShouldDie = false;

    _packetBuffer = (char*)calloc(_maxPacketSize, sizeof(char));
    _inboundThread = thread(&ConnectionBuffer::doInboundBuffering, this);
  }
  if(!_outboundThread.joinable()) {
    _outboundShouldDie = false;

    _outboundThread = thread(&ConnectionBuffer::doOutboundBuffering, this);
  }
}

void ConnectionBuffer::stopBuffering() {
  if(_inboundThread.joinable()) {
    _inboundShouldDie = true;
    _inboundThread.join();

    free(_packetBuffer);
    _packetBuffer = 0;
  }
  if(_outboundThread.joinable()) {
    _outboundShouldDie = true;
    _outboundThread.join();
  }
}

void ConnectionBuffer::setMaxBufferSize(unsigned int maxPackets) {
  _maxBufferSize = maxPackets;
}

unsigned int ConnectionBuffer::getMaxBufferSize() {
  return _maxBufferSize;
}

void ConnectionBuffer::setMaxPacketSize(unsigned int maxSize) {
  _maxPacketSize = maxSize;
  unique_lock<mutex> lock(_inboundQueueLock);
  _packetBuffer = (char*)realloc(_packetBuffer, _maxPacketSize*sizeof(char));
}

unsigned int ConnectionBuffer::getMaxPacketSize() {
  return _maxPacketSize;
}

bool ConnectionBuffer::providePacket(const Packet &packet) {
  unique_lock<mutex> lock(_outboundQueueLock);
  _outbound.push(packet);
  if(_outbound.size() > _maxBufferSize) {
    _outbound.pop();
    _droppedPackets++;
    return false;
  } else {
    _outboundPackets++;
    return true;
  }
}

bool ConnectionBuffer::consumePacket(Packet &packet) {
  unique_lock<mutex> lock(_inboundQueueLock);
  if(_inbound.empty()) {
    return false;
  } else {
    packet = _inbound.front();
    _inbound.pop();
    _inboundPackets--;
    return true;
  }
}

unsigned short ConnectionBuffer::getLocalPort() const {
  if(_socket) {
    return _socket->getLocalPort();
  } else {
    return 0;
  }
}

void ConnectionBuffer::logStatistics() {
  Info("Inbound packets: " << _inboundPackets);
  Info("Outbound packets: " << _outboundPackets);
  Info("Dropped packets: " << _droppedPackets);
  Info("Sent packets: " << _sentPackets);
  Info("Received packets: " << _receivedPackets);
}
