#ifndef GAMECORE_H
#define GAMECORE_H

#include "game/bobjectmanager.h"
#include "world/world.h"

#include <string>

using namespace std;

class GameCore {
public:
  GameCore(const string& rawSet);
  ~GameCore();

private:
  BObjectManager* _objectManager;
  World* _world;
};

#endif
