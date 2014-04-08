#include "io/remotefrontend.h"

RemoteFrontEnd::RemoteFrontEnd(const NetAddress& addr, const string& name): _addr(addr), _name(name), _tcpBuffer(0) {
}

RemoteFrontEnd::~RemoteFrontEnd() {
}

bool RemoteFrontEnd::connectSender() {
  if(_tcpBuffer) {
    Warn("Client is already connected");
    return false;
  } else {
    _tcpBuffer = new TCPBuffer();
    if(_tcpBuffer->connect(_addr)) {
      _tcpBuffer->startBuffering();
      return true;
    } else {
      delete _tcpBuffer;
      return false;
    }
  }
}

void RemoteFrontEnd::disconnectSender() {
  if(!_tcpBuffer) {
    Error("Client is not connected");
    return false;
  }
  _tcpBuffer->stopBuffering();
  delete _tcpBuffer;
  _tcpBuffer = 0;
}

void RemoteFrontEnd::sendEvent(const GameEvent& event) {
  #pragma message "Event packing and buffering will go here"
}
