#include "net/tcpbuffer.h"
#include "util/assertion.h"

#include <cstring>

TCPBuffer::TCPBuffer(unsigned short localPort): _serializationBuffer(0), _localPort(localPort) {
  _socket = new TCPSocket();
}

TCPBuffer::TCPBuffer(TCPSocket *establishedSocket): _serializationBuffer(0), _localPort(0) {
  _socket = establishedSocket;
}

TCPBuffer::~TCPBuffer() {
  if(_socket) { delete getSocket(); }
}

bool TCPBuffer::isConnected() {
  return getSocket()->isConnected();
}

bool TCPBuffer::connect(const NetAddress& dest) {
  if(!getSocket()->isConnected()) {
    return getSocket()->connectSocket(dest, _localPort);
  } else {
    Error("Already connected");
    return false;
  }
}

void TCPBuffer::startBuffering() {
  if(!_serializationBuffer) {
    _serializationBuffer = (char*)calloc(_maxPacketSize, sizeof(char));
  }
  ConnectionBuffer::startBuffering();
}

void TCPBuffer::stopBuffering() {
  ConnectionBuffer::stopBuffering();
  if(_serializationBuffer) {
    free(_serializationBuffer);
  }
}

void TCPBuffer::doInboundBuffering() {
  int totalBufferSize, currentOffset,
    packetSize;
  unsigned int dataSize;
  char *dataBuffer;
  char *currentPacket;

  Debug("Waiting for TCPSocket to connect before starting inbound buffering");
  while(!getSocket()->isConnected()) { sleep(1); }

  Debug("Entering TCPBuffer inbound packet buffering loop");
  while(!_inboundShouldDie) {
    _inboundQueueLock.lock();

    // Get the next packet from the socket
    getSocket()->recv(_packetBuffer, totalBufferSize, _maxBufferSize);
    currentOffset = 0;
    dataBuffer = 0;
    while(currentOffset < totalBufferSize) {
      currentPacket = _packetBuffer + currentOffset;
      packetSize = tcpDeserialize(currentPacket, &dataBuffer, dataSize);

      // Update received stats
      _receivedPackets++;

      // Push the incoming packet onto the queue
      _inbound.push(Packet(dataBuffer, dataSize));
      if(_inbound.size() > _maxBufferSize) {
        _inbound.pop();
        _droppedPackets++;
      } else {
        _inboundPackets++;
      }

      currentOffset += packetSize;
    }
    _inboundQueueLock.unlock();
  }
}

void TCPBuffer::doOutboundBuffering() {
  Packet packet;
  int serializedSize;

  Debug("Waiting for TCPSocket to connect before starting outbound buffering");
  while(!getSocket()->isConnected()) { sleep(1); }

  Debug("Entering TCPBuffer outbound packet buffering loop");
  while(!_outboundShouldDie) {
    _outboundQueueLock.lock();
    if(!_outbound.empty()) {
      // Pop the next outgoing packet off the queue
      packet = _outbound.front();
      _outbound.pop();
      _outboundPackets--;

      // TODO - This is where we'd sleep the thread when throttling bandwidth

      // Send the next outgoing packet to the socket
      serializedSize = tcpSerialize(_serializationBuffer, packet.data, (unsigned int)packet.size, _maxPacketSize);
      getSocket()->send(_serializationBuffer, serializedSize);
      _sentPackets++;
    }
    _outboundQueueLock.unlock();
  }
}

int TCPBuffer::tcpSerialize(char *dest, const char *src, unsigned int size, unsigned int maxSize) {
  uint32_t totalSize = sizeof(uint32_t) + size;

  ASSERT(totalSize <= maxSize, "Total packet size exceeds maximum size");
  ((uint32_t*)dest)[0] = totalSize;

  memcpy((void*)(dest + sizeof(uint32_t)), (void*)src, size);

  return totalSize;
}

int TCPBuffer::tcpDeserialize(const char *srcData, char **data, unsigned int &size) {
  size = ((uint32_t*)srcData)[0] - sizeof(uint32_t);
  *data = (char*)(srcData + sizeof(uint32_t));

  return sizeof(int) + size;
}
