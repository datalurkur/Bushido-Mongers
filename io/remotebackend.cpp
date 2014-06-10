#include "io/remotebackend.h"
#include "io/gameevent.h"

RemoteBackEnd::RemoteBackEnd(TCPSocket* socket): _socket(socket), _shouldDie(false) {
  _incoming = thread(&RemoteBackEnd::bufferIncoming, this);
}

RemoteBackEnd::~RemoteBackEnd() {
  Info("Shutting down remote backend");
  if(_incoming.joinable()) {
    _shouldDie = true;
    _incoming.join();
  }

  delete _socket;
}

void RemoteBackEnd::sendToClient(SharedGameEvent event) {
  GameEvent* e = event.get();

  // Serialize the event
  ostringstream str;
  GameEvent::Pack(e, str);

  Debug("Sending game event");
  _buffer.sendPacket(_socket, str);
}

void RemoteBackEnd::sendToClient(EventQueue&& queue) {
  for(auto event : queue) {
    sendToClient(event);
  }
}

void RemoteBackEnd::bufferIncoming() {
  Info("Listening for incoming game events");
  while(true) {
    PacketBufferInfo i;
    while(!_shouldDie && !_buffer.getPacket(_socket, i)) {}
    if(_shouldDie) { return; }

    Debug("Received game event");
    istringstream stream(i.str.str());
    GameEvent* event = GameEvent::Unpack(stream);
    if(event) {
      sendToServer(event);
      delete event;
    } else {
      Warn("Failed to deserialize event");
    }
  }
  Info("Stopped listening for game events");
}
