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

  Debug("Attempting to assign name");
  AssignNameEvent event(name);
  sendToServer(&event);

  return true;
}

void RemoteFrontEnd::disconnectSender() {
  if(_incoming.joinable()) {
    _shouldDie = true;
    _incoming.join();
  }
  _socket.disconnect();
}

void RemoteFrontEnd::sendToServer(GameEvent* event) {
  ostringstream str;
  GameEvent::Pack(event, str);

  Debug("Sending event");
  _buffer.sendPacket(&_socket, str);
}

void RemoteFrontEnd::bufferIncoming() {
  Debug("Waiting for incoming events");
  while(true) {
    PacketBufferInfo i;
    while(!_shouldDie && !_buffer.getPacket(&_socket, i)) {}
    if(_shouldDie) { return; }

    Debug("Received event");
    istringstream stream(i.str.str());
    GameEvent* event = GameEvent::Unpack(stream);
    if(event) {
      SharedGameEvent e(event);
      sendToClient(e);
    } else {
      Warn("Failed to deserialize event");
    }
  }
  Debug("Stopped listening for game events");
}
