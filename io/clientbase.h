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
  virtual void disconnectSender() = 0;
  virtual void sendToServer(GameEvent* event) = 0;
  virtual void sendToClient(EventQueue* queue) = 0;
  virtual void sendToClient(GameEvent* event) = 0;

  void createCharacter(const string& name);
  void loadCharacter(BObjectID id);
  void unloadCharacter();
  void moveCharacter(const IVec2& dir);

private:
  void consumeEvents();
};

#endif
