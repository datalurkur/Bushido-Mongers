#ifndef SERVERBASE_H
#define SERVERBASE_H

#include "util/bimap.h"
#include "game/core.h"
#include "io/eventqueue.h"

#include <thread>
#include <atomic>

using namespace std;

class ClientBase;
struct GameEvent;

class ServerBase {
public:
  ServerBase(const string& rawSet);
  virtual ~ServerBase();

  void start();
  void stop();
  bool isRunning();

  bool assignClient(ClientBase* client, const string& name);
  void removeClient(ClientBase* client);

  void clientEvent(ClientBase* client, GameEvent* event);

private:
  void setup(const string& rawSet);

  void innerLoop();

private:
  atomic<bool> _shouldDie;
  thread _loopThread;
  mutex _lock;
  GameCore* _core;

  BiMap<string, ClientBase*> _assignedClients;
  BiMap<PlayerID, ClientBase*> _assignedIDs;

  // A player ID is essentially a unique identifier for a player login
  // At first launch, these will be allocated as needed, and will be loaded from a player manifest once a player has been established
  map<string, PlayerID> _playerIDs;
  PlayerID _nextPlayerID;
};

#endif
