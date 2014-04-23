#ifndef LOCAL_BACKEND_H
#define LOCAL_BACKEND_H

#include "io/clientbase.h"
#include "world/clientworld.h"

class LocalBackEnd: virtual public ClientBase {
public:
  LocalBackEnd();
  ~LocalBackEnd();

  void sendToClient(GameEvent* event);

private:
  void updateMap();

private:
  ClientWorld* _world;
};

#endif
