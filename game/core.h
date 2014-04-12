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
  void processPlayerEvent(PlayerID player, GameEvent* event, EventQueue& results);
  bool isEventVisibleToPlayer(PlayerID player, GameEvent* event);

  // Player/character maintenance
  void createCharacter(PlayerID player, const string& characterType, EventQueue& results);
  void loadCharacter(PlayerID player, BObjectID characterID, EventQueue& results);
  void unloadCharacter(PlayerID player, EventQueue& results);
  void moveCharacter(PlayerID player, const IVec2& dir, EventQueue& results);

  bool isCharacterActive(PlayerID player);

private:
  void getViewFrom(PlayerID player, const IVec2& pos, set<IVec2>& visibleTiles);
  bool checkCharacterSanity(PlayerID player);

private:
  BObjectManager* _objectManager;
  World* _world;

  BiMap<PlayerID, BObjectID> _playerMap;

  map<int, list<IVec2> > _precomputedSight;
  map<PlayerID, set<IVec2> > _previousView;
};

#endif
