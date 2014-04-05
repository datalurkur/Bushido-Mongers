#ifndef CLIENTBASE_H
#define CLIENTBASE_H

#include "io/gameevent.h"

#include <string>
using namespace std;

class ClientBase {
public:
  ClientBase(const string& name);
  ~ClientBase();

  virtual bool connect() = 0;
  virtual void disconnect() = 0;
  virtual void sendEvent(const GameEvent* event) = 0;

  void createCharacter();

protected:
  string _name;
};

#endif
