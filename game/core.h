#ifndef GAMECORE_H
#define GAMECORE_H

#include "game/bobjectmanager.h"
#include "world/world.h"

#include <string>
#include <thread>
#include <atomic>

using namespace std;

typedef int PlayerID;

class GameCore {
public:
  GameCore();
  ~GameCore();

  bool generateWorld(const string& rawSet, int size);
  bool destroyWorld();

  bool start();
  bool stop();

  bool isRunning() const;

  // Player/character maintenance
  bool createCharacter(PlayerID player, const string& characterType, BObjectID& characterID);
  bool loadCharacter(PlayerID player, BObjectID& characterID);
  bool unloadCharacter(PlayerID player);

  bool isCharacterActive(PlayerID player);

private:
  void innerLoop();

private:
  BObjectManager* _objectManager;
  World* _world;

  atomic<bool> _isRunning;
  thread _thinkThread;

  map<PlayerID, BObjectID> _playerMap;
};

#endif
