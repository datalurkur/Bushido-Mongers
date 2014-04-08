#ifndef REMOTE_FRONTEND_H
#define REMOTE_FRONTEND_H

#include "io/clientbase.h"
#include "net/netaddress.h"
#include "net/tcpbuffer.h"

using namespace std;

class RemoteFrontEnd: virtual public ClientBase {
public:
  RemoteFrontEnd(const NetAddress& addr, const string& name);
  ~RemoteFrontEnd();

  bool connectSender();
  void disconnectSender();
  void sendToServer(GameEvent* event);

private:
  NetAddress _addr;
  string _name;

  TCPBuffer* _tcpBuffer;
};

#endif
