#include "net/tcpsocket.h"
#include "util/assertion.h"
#include "util/log.h"

TCPSocket::TCPSocket(bool blocking): Socket(blocking) {
}

TCPSocket::TCPSocket(int establishedSocketHandle, bool blocking): Socket(blocking) {
  int error = 0;
  socklen_t errorLength = sizeof(error);
  if(getsockopt(establishedSocketHandle, SOL_SOCKET, SO_ERROR, (char*)&error, (socklen_t*)&errorLength) == 0) {
    _socketHandle = establishedSocketHandle;
    _state = Connected;
  } else {
    Error("Failed to create TCPSocket from preestablished socket handle, socket reports error code " << error);
  }
}

TCPSocket::~TCPSocket() {
}

bool TCPSocket::connectSocket(const NetAddress &dest, unsigned short localPort) {
  int ret;

  if(!createSocket(SOCK_STREAM, IPPROTO_TCP)) { return false; }
  if(!bindSocket(localPort)) { return false; }

  Info("Connecting to " << dest << " (local port " << localPort << ")");
  _mutex->lock();
  ret = connect(_socketHandle, dest.getSockAddr(), dest.getSockAddrSize());
  _mutex->unlock();

  if(ret < 0) {
    int err = Socket::LastSocketError();
    switch(err) {
    case E_ADDR_IN_USE:
      Error("TCPSocket failed to connect: address in use.");
      return false;
    case E_ALREADY:
      Error("TCPSocket failed to connect: socket busy.");
    case E_IN_PROGRESS:
      _state = Connecting;
      return true;
    default:
      Error("TCPSocket failed to connect: unknown.");
      return false;
    };
  } else {
    _state = Connected;
    return true;
  }
}

bool TCPSocket::isConnected() {
  int error, errorLength, ret;

  errorLength = sizeof(error);
  _mutex->lock();
  ret = getsockopt(_socketHandle, SOL_SOCKET, SO_ERROR, (char*)&error, (socklen_t*)&errorLength);
  _mutex->unlock();

  if(ret == 0) {
    if(error == 0) { return true; }
    else { return false; }
  } else {
    Error("Failed to get socket options");
    return false;
  }
}

bool TCPSocket::send(const char *data, unsigned int size) {
  return Socket::send(data, size, 0, 0);
}

void TCPSocket::recv(char *data, int &size, unsigned int maxSize) {
  int addrSize;
  Socket::recv(data, size, maxSize, 0, addrSize);
}
