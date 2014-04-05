#ifndef CLIENTBASE_H
#define CLIENTBASE_H

#include "game/bobject.h"

#include <string>
using namespace std;

struct GameEvent;

class ClientBase {
public:
  ClientBase();
  virtual ~ClientBase();

  virtual bool connectSender() = 0;
  virtual void disconnectSender() = 0;
  virtual void sendEvent(const GameEvent* event) = 0;
  virtual void receiveEvent(const GameEvent* event) = 0;

  void createCharacter(const string& name);
  void loadCharacter(BObjectID id);
  void unloadCharacter();
};

#endif
