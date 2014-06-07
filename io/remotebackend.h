#ifndef REMOTE_BACKEND_H
#define REMOTE_BACKEND_H

#include "io/clientbase.h"
#include "net/tcpbuffer.h"

class RemoteBackEnd: virtual public ClientBase {
public:
  RemoteBackEnd(TCPSocket* socket);
  ~RemoteBackEnd();

  void sendToClient(SharedGameEvent event);
  void sendToClient(EventQueue&& queue);

private:
  void bufferIncoming();

private:
  TCPBuffer* _buffer;

  atomic<bool> _shouldDie;
  thread _incoming;
};

#endif
