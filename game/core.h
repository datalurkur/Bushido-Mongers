#ifndef GAMECORE_H
#define GAMECORE_H

#include "game/bobjectmanager.h"
#include "io/gameevent.h"
#include "io/eventqueue.h"
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

  void update(int elapsed, EventQueue& events);
  bool isEventVisibleToPlayer(GameEvent* event, PlayerID player);

  // Player/character maintenance
  bool createCharacter(PlayerID player, const string& characterType, EventQueue& events);
  bool loadCharacter(PlayerID player, BObjectID characterID, EventQueue& events);
  bool unloadCharacter(PlayerID player);

  bool isCharacterActive(PlayerID player);

private:
  void getViewFrom(PlayerID player, const IVec2& pos, set<IVec2>& visibleTiles);

private:
  BObjectManager* _objectManager;
  World* _world;

  BiMap<PlayerID, BObjectID> _playerMap;
};

#endif
