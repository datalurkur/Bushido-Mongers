#ifndef REMOTE_FRONTEND_H
#define REMOTE_FRONTEND_H

#include "io/clientbase.h"
#include "net/netaddress.h"
#include "net/tcpbuffer.h"

#include <atomic>
#include <thread>

using namespace std;

class RemoteFrontEnd: virtual public ClientBase {
public:
  RemoteFrontEnd(const NetAddress& addr);
  ~RemoteFrontEnd();

  bool connectSender(const string& name);
  bool isConnected();
  void disconnectSender();
  bool sendToServer(GameEvent* event);

private:
  void bufferIncoming();

private:
  NetAddress _addr;

  TCPSocket _socket;
  TCPBuffer _buffer;

  atomic<bool> _shouldDie;
  thread _incoming;
};

#endif
