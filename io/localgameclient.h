#ifndef LOCALGAMECLIENT_H
#define LOCALGAMECLIENT_H

#include "io/clientbase.h"

class GameServer;

class LocalGameClient: public ClientBase {
public:
  LocalGameClient(GameServer* server, const string& name);
  ~LocalGameClient();

  void sendEvent(const GameEvent* event);
  bool connect();
  void disconnect();

private:
  GameServer* _server;
};

#endif
