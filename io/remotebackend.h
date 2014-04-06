#ifndef REMOTE_BACKEND_H
#define REMOTE_BACKEND_H

#include "io/clientbase.h"

class RemoteBackEnd: virtual public ClientBase {
public:
  RemoteBackEnd();
  ~RemoteBackEnd();

  void receiveEvent(const GameEvent* event);
};

#endif
