#ifndef REMOTE_BACKEND_H
#define REMOTE_BACKEND_H

#include "io/clientbase.h"
#include "net/tcpbuffer.h"

#include <atomic>
#include <thread>

using namespace std;

class RemoteBackEnd: virtual public ClientBase {
public:
  RemoteBackEnd(TCPSocket* socket);
  ~RemoteBackEnd();

  void sendToClient(EventQueue* queue);
  void sendToClient(GameEvent* event);

private:
  void bufferIncoming();

private:
  TCPSocket* _socket;
  TCPBuffer _buffer;

  atomic<bool> _shouldDie;
  thread _incoming;
};

#endif
