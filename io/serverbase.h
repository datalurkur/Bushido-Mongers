#ifndef SERVERBASE_H
#define SERVERBASE_H

#include "game/core.h"

class ClientBase;
struct GameEvent;

class ServerBase {
public:
  ServerBase(const string& rawSet);
  ~ServerBase();

  void start();
  void stop();

  bool assignClient(ClientBase* client, const string& name);
  void removeClient(ClientBase* client);

  void clientEvent(ClientBase* client, const GameEvent* event);

private:
  void setup(const string& rawSet);

private:
  mutex _lock;
  GameCore* _core;

  map<string, ClientBase*> _assignedClients;
  map<ClientBase*, string> _assignedNames;
};

#endif
