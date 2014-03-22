#include "net/clientprovider.h"

ClientProvider::~ClientProvider() {
  ConnectionBufferMap::iterator itr;
  TCPBuffer *buffer;
  for(itr = _buffers.begin(); itr != _buffers.end(); itr++) {
    buffer = (TCPBuffer*)itr->second;
    buffer->stopBuffering();
    delete buffer;
  }
}

bool ClientProvider::sendPacket(const Packet &packet) {
  TCPBuffer *buffer;
  ConnectionBufferMap::iterator itr = _buffers.find(packet.addr);
  if(itr == _buffers.end()) {
    buffer = new TCPBuffer(packet.addr);
    buffer->startBuffering();
    _buffers[packet.addr] = buffer;
  } else {
    buffer = (TCPBuffer*)itr->second;
  }
  return buffer->providePacket(packet);
}
