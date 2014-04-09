#ifndef LOCAL_BACKEND_H
#define LOCAL_BACKEND_H

#include "io/clientbase.h"

class LocalBackEnd: virtual public ClientBase {
public:
  LocalBackEnd();
  ~LocalBackEnd();

  void sendToClient(GameEvent* event);
};

#endif