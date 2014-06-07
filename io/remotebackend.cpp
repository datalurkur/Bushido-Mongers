#include "io/remotebackend.h"
#include "io/gameevent.h"

RemoteBackEnd::RemoteBackEnd(TCPSocket* socket): _shouldDie(false) {
  _buffer = new TCPBuffer(socket);
  _buffer->startBuffering();

  _incoming = thread(&RemoteBackEnd::bufferIncoming, this);
}

RemoteBackEnd::~RemoteBackEnd() {
  if(_incoming.joinable()) {
    _shouldDie = true;
    _incoming.join();
  }

  _buffer->stopBuffering();
  delete _buffer;
}

void RemoteBackEnd::sendToClient(SharedGameEvent event) {
  // Serialize the event
  ostringstream str;
  GameEvent::Pack(event, str);

  // Construct the packet and send it
  Packet pkt(str.c_str(), str.size());
  _buffer->providePacket(pkt);
}

void RemoteBackEnd::sendToClient(EventQueue&& queue) {
  for(auto event : queue) {
    sendToClient(event);
  }
}

void RemoteBackEnd::bufferIncoming() {
  while(!_shouldDie) {
    Packet pkt;
    if(_buffer->consumePacket(pkt)) {
      istringstream str(pkt.data);
      GameEvent* event = GameEvent::Unpack(str);
    }
  }
}
