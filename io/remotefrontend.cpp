#include "io/remotefrontend.h"
#include "util/log.h"

RemoteFrontEnd::RemoteFrontEnd(const NetAddress& addr): _addr(addr) {
}

RemoteFrontEnd::~RemoteFrontEnd() {
  if(_incoming.joinable()) {
    _shouldDie = true;
    _incoming.join();
  }
}

bool RemoteFrontEnd::connectSender(const string& name) {
  if(_socket.isConnected()) {
    Warn("Client is already connected");
    return false;
  } else if(!_socket.connectSocket(_addr)) {
    Error("Failed to connect");
    return false;
  }

  if(!_incoming.joinable()) {
    _shouldDie = false;
    _incoming = thread(&RemoteFrontEnd::bufferIncoming, this);
  }

  sendToServer(new AssignNameEvent(name));

  return true;
}

bool RemoteFrontEnd::isConnected() {
  return _socket.isConnected();
}

void RemoteFrontEnd::disconnectSender() {
  if(_incoming.joinable()) {
    _shouldDie = true;
    _incoming.join();
  }
  _socket.disconnect();
}

bool RemoteFrontEnd::sendToServer(GameEvent* event) {
  ostringstream str(ios_base::binary);
  GameEvent::Pack(event, str);
  delete event;
  return _buffer.sendPacket(&_socket, str);
}

void RemoteFrontEnd::bufferIncoming() {
  while(true) {
    PacketBufferInfo i;
    while(!_shouldDie && !_buffer.getPacket(&_socket, i)) {}
    if(_shouldDie) { return; }

    istringstream stream(i.str.str());
    GameEvent* event = GameEvent::Unpack(stream);
    if(event) {
      sendToClient(event);
      delete event;
    } else {
      Warn("Failed to deserialize event");
    }
  }
}
