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
  if(!createSocket(SOCK_STREAM, IPPROTO_TCP)) { return false; }
  if(!bindSocket(localPort)) { return false; }

  Info("Connecting to " << dest << " (local port " << localPort << ")");
  unique_lock<mutex> lock(_mutex);
  if(connect(_socketHandle, dest.getSockAddr(), dest.getSockAddrSize()) < 0) {
    int err = Socket::LastSocketError();
    switch(err) {
    case E_ADDR_IN_USE:
      Error("TCPSocket failed to connect: address in use.");
      return false;
    case E_ALREADY:
      Error("TCPSocket failed to connect: socket busy.");
      return false;
    case E_IN_PROGRESS: {
      _state = Connecting;
      fd_set writeSet;
      FD_ZERO(&writeSet);
      FD_SET(_socketHandle, &writeSet);
      timeval timeout{3, 0};
      int ret = select(FD_SETSIZE, 0, &writeSet, 0, &timeout);
      if(ret > 0) {
        lock.unlock();
        return isConnected();
      } else if(ret == 0) {
        Error("Connection timed out");
        return false;
      } else {
        Error("Connection threw an exception");
        return false;
      }
    }
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
  int error, ret;
  socklen_t errorLength;

  errorLength = sizeof(error);
  unique_lock<mutex> lock(_mutex);
  ret = getsockopt(_socketHandle, SOL_SOCKET, SO_ERROR, &error, &errorLength);

  if(ret == 0) {
    if(error == 0) { return true; }
    else { return false; }
  } else {
    Error("Failed to get socket options");
    return false;
  }
}

bool TCPSocket::send(const char *data, unsigned int size) {
  bool ret = Socket::send(data, size, 0, 0);
  return ret;
}

void TCPSocket::recv(char *data, int &size, unsigned int maxSize) {
  int addrSize;
  Socket::recv(data, size, maxSize, 0, addrSize);
}

bool TCPSocket::recvBlocking(char* data, int& size, unsigned int maxSize, int timeout) {
  fd_set readSet;
  FD_ZERO(&readSet);
  FD_SET(_socketHandle, &readSet);
  timeval timeoutStruct{timeout, 0};
  int ret = select(FD_SETSIZE, &readSet, 0, 0, &timeoutStruct);
  if(ret > 0) {
    size = ::recv(_socketHandle, data, maxSize, 0);
    return (size > 0);
  } else if(ret < 0) {
    Warn("Socket error occurred, aborting");
    size = 0;
    return false;
  } else {
    size = 0;
    return false;
  }
}
