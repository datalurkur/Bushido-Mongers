#ifndef REMOTEGAMECLIENT_H
#define REMOTEGAMECLIENT_H

#include "io/clientbase.h"
#include "net/tcpbuffer.h"

class RemoteGameClient: public ClientBase {
public:
  RemoteGameClient(const NetAddress& addr, const string& name);
  ~RemoteGameClient();

private:
  void protocolLoop();

private:
  NetAddress _addr;
  atomic<ClientState> _state;
  atomic<bool> _stayAlive;
  TCPBuffer* _tcpBuffer;

  thread _protocolThread;
  mutex _protocolLock;

  string _name;
};

#endif
