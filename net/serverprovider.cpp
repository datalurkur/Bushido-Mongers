#include "net/serverprovider.h"
#include "util/assertion.h"

ServerProvider::ServerProvider(unsigned short localPort) {
  _listenSocket = new ListenSocket(this);
  _listenSocket->startListening(localPort);
}

ServerProvider::~ServerProvider() {
  delete _listenSocket;

  ConnectionBufferMap::iterator itr;
  TCPBuffer *buffer;
  for(itr = _buffers.begin(); itr != _buffers.end(); itr++) {
    buffer = (TCPBuffer*)itr->second;
    buffer->stopBuffering();
    delete buffer;
  }
}

bool ServerProvider::sendPacket(const NetAddress& dest, const Packet &packet) {
  ConnectionBufferMap::iterator itr = _buffers.find(dest);

  if(itr == _buffers.end()) {
      Warn("Unable to send packet: unknown host " << dest);
      return false;
  }

  return itr->second->providePacket(packet);
}

unsigned short ServerProvider::getLocalPort() {
  return _listenSocket->getLocalPort();
}

bool ServerProvider::onSocketCreation(const NetAddress &client, TCPSocket *socket) {
  ConnectionBufferMap::iterator itr = _buffers.find(client);

  if(itr != _buffers.end()) {
    // This connection already exists, kill the old one and replace it with this one
    delete itr->second;
    _buffers.erase(itr);
  }

  _buffers[client] = new TCPBuffer(socket);
  ((TCPBuffer*)_buffers[client])->startBuffering();
  return true;
}
