#ifndef TCPSOCKET_H
#define TCPSOCKET_H

#include "net/socket.h"
#include "net/netaddress.h"

class TCPSocket: public Socket {
public:
  TCPSocket(bool blocking = false);
  TCPSocket(int establishedSocketHandle, bool blocking = false);
  virtual ~TCPSocket();

  bool connectSocket(const NetAddress &dest, unsigned short localPort = 0);
  bool isConnected();

  bool send(const char *data, unsigned int size);
  void recv(char *data, int &size, unsigned int maxSize);

  // Intended for use by nonblocking sockets that want to block until data is available (while still allowing data to be sent)
  bool recvBlocking(char *data, int &size, unsigned int maxSize, int timeout = 3);
};

#endif
