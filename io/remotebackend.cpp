#include "io/remotebackend.h"
#include "io/gameevent.h"

RemoteBackEnd::RemoteBackEnd(TCPSocket* socket): _socket(socket), _shouldDie(false) {
  _incoming = thread(&RemoteBackEnd::bufferIncoming, this);
}

RemoteBackEnd::~RemoteBackEnd() {
  if(_incoming.joinable()) {
    _shouldDie = true;
    _incoming.join();
  }

  delete _socket;
}

void RemoteBackEnd::sendToClient(SharedGameEvent event) {
  GameEvent* e = event.get();

  // Serialize the event
  ostringstream str(ios_base::binary);
  GameEvent::Pack(e, str);

  _buffer.sendPacket(_socket, str);
}

void RemoteBackEnd::sendToClient(EventQueue&& queue) {
  for(auto event : queue) {
    sendToClient(event);
  }
}

void RemoteBackEnd::bufferIncoming() {
  while(true) {
    PacketBufferInfo i;
    while(!_shouldDie && !_buffer.getPacket(_socket, i)) {}
    if(_shouldDie) { return; }

    istringstream stream(i.str.str());
    GameEvent* event = GameEvent::Unpack(stream);
    if(event) {
      sendToServer(event);
      delete event;
    } else {
      Warn("Failed to deserialize event");
    }
  }
}
