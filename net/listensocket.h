#ifndef LISTENSOCKET_H
#define LISTENSOCKET_H

#include "net/tcpsocket.h"
#include "net/netaddress.h"

#include <mutex>
#include <thread>

class SocketCreationListener {
public:
  // Returns true if the connection should be left active, false if it should be refused
  virtual bool onSocketCreation(const NetAddress &client, TCPSocket *socket) { return false; }
};

class ListenSocket: public Socket {
public:
  ListenSocket(SocketCreationListener *acceptListener);
  virtual ~ListenSocket();

  bool startListening(unsigned short localPort = 0);
  void stopListening();

  void doListening();

private:
  static unsigned int DefaultMaxClients;

private:
  SocketCreationListener *_acceptListener;

  thread _listenThread;
  unsigned int _maxClients;
  
  atomic<bool> _shouldDie;
};

#endif
