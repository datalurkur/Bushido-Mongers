#ifndef CLIENTBASE_H
#define CLIENTBASE_H

#include "io/eventqueue.h"
#include "game/bobject.h"
#include "util/vector.h"

#include <string>
using namespace std;

struct GameEvent;

class ClientBase {
public:
  ClientBase();
  virtual ~ClientBase();

  virtual bool connectSender(const string& name) = 0;
  virtual bool isConnected() = 0;
  virtual void disconnectSender() = 0;
  virtual bool sendToServer(GameEvent* event) = 0;
  virtual bool sendToClient(EventQueue* queue) = 0;
  virtual bool sendToClient(GameEvent* event) = 0;

private:
  void consumeEvents();
};

#endif
