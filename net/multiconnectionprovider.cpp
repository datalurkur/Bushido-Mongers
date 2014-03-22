#include "net/multiconnectionprovider.h"

void MultiConnectionProvider::getAndPrioritizePackets() {
  ConnectionBufferMap::iterator itr;
  for(itr = _buffers.begin(); itr != _buffers.end(); itr++) {
    Packet packet;
    while(itr->second->consumePacket(packet)) {
      _prioritizedPackets.push(packet);
    }
  }
}

bool MultiConnectionProvider::recvPacket(Packet &packet) {
  getAndPrioritizePackets();
  if(_prioritizedPackets.empty()) { return false; }
  else {
    packet = _prioritizedPackets.top();
    _prioritizedPackets.pop();
    return true;
  }
}
