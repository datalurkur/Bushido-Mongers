#ifndef GAMECORE_H
#define GAMECORE_H

#include "game/bobjectmanager.h"
#include "world/world.h"

#include <string>
#include <thread>
#include <atomic>

using namespace std;

class GameCore {
public:
  GameCore();
  ~GameCore();

  bool generateWorld(const string& rawSet, int size);
  bool destroyWorld();

  bool start();
  bool stop();

  bool isRunning() const;

private:
  void innerLoop();

private:
  BObjectManager* _objectManager;
  World* _world;

  atomic<bool> _isRunning;
  thread _thinkThread;
};

extern void RunGame(GameCore* core);

#endif
