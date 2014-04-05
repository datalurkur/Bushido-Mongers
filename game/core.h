#ifndef GAMECORE_H
#define GAMECORE_H

#include "game/bobjectmanager.h"
#include "io/gameevent.h"
#include "world/world.h"
#include "util/bimap.h"

#include <string>

using namespace std;

typedef int PlayerID;

class GameCore {
public:
  GameCore();
  ~GameCore();

  bool generateWorld(const string& rawSet, int size);
  bool destroyWorld();

  void update(int elapsed, list<GameEvent>& events);
  bool isEventVisibleToPlayer(const GameEvent& event, PlayerID player);

  // Player/character maintenance
  bool createCharacter(PlayerID player, const string& characterType, BObjectID& characterID);
  bool loadCharacter(PlayerID player, BObjectID& characterID);
  bool unloadCharacter(PlayerID player);

  bool isCharacterActive(PlayerID player);

private:
  BObjectManager* _objectManager;
  World* _world;

  BiMap<PlayerID, BObjectID> _playerMap;
};

#endif
