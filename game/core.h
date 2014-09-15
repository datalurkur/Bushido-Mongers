#ifndef GAMECORE_H
#define GAMECORE_H

#include "game/bobjectmanager.h"
#include "game/objectobserver.h"
#include "io/gameevent.h"
#include "io/eventmap.h"
#include "world/world.h"
#include "util/bimap.h"
#include "util/quadtree.h"

#include <string>

using namespace std;

typedef int PlayerID;

class GameCore {
public:
  GameCore();
  ~GameCore();

  bool generateWorld(const string& rawSet);
  bool destroyWorld();

  void update(int elapsed, EventMap<PlayerID>& events);
  void processPlayerEvent(PlayerID player, GameEvent* event, EventMap<PlayerID>& results);

  // Player/character maintenance
  void createCharacter(PlayerID player, const string& characterType, EventMap<PlayerID>& results);
  void loadCharacter(PlayerID player, BObjectID characterID, EventMap<PlayerID>& results);
  void unloadCharacter(PlayerID player, EventMap<PlayerID>& results);
  void moveCharacter(PlayerID player, const IVec2& dir, EventMap<PlayerID>& results);

  bool isCharacterActive(PlayerID player);

private:
  void getViewFrom(PlayerID player, const IVec2& pos, set<IVec2>& visibleTiles);
  bool checkCharacterSanity(PlayerID player);
  void packRaws(EventQueue* results);

  void setObjectAwareness(BObjectID id, Area* area);
  void onEvent(GameEvent* event, EventMap<PlayerID>& results);

private:
  // World and objects
  BObjectManager* _objectManager;
  World* _world;

  // Player <-> Character mapping
  BiMap<PlayerID, BObjectID> _playerMap;

  // Visibility
  map<int, list<IVec2> > _precomputedSight;
  map<PlayerID, ObjectObserver> _observers;

  // Rough awareness map
  map<Area*, set<BObjectID> > _areaListeners;
  map<BObjectID, Area*> _listenerAreas;
};

#endif
