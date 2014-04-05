#ifndef REMOTEGAMECLIENT_H
#define REMOTEGAMECLIENT_H

#include "io/clientbase.h"
#include "net/tcpbuffer.h"

class RemoteGameClient: public ClientBase {
public:
  enum ClientState {
    Disconnected,
    Waiting,
    Ready
  };

public:
  RemoteGameClient(const NetAddress& addr, const string& name);
  ~RemoteGameClient();

  ClientState getState() const;

  bool connect();
  bool disconnect();
  void toServer(const GameEvent* event);
  void fromServer(const GameEvent* event);

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
