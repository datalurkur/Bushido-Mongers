#include "game/core.h"
#include "world/generator.h"

#include <unistd.h>

GameCore::GameCore(): _objectManager(0), _world(0), _isRunning(false) {}

GameCore::~GameCore() {
  if(isRunning()) {
    stop();
  }
  destroyWorld();
}

bool GameCore::generateWorld(const string &rawSet, int size) {
  if(_world) {
    Error("World already created");
    return false;
  }
  Info("Game generating");

  _objectManager = new BObjectManager(rawSet);

  // Maybe it'll be interesting in the future to allow tweaks to these parameters, but for now let's just focus on getting a world created with minimal user interaction
  _world = WorldGenerator::GenerateWorld(size, 0.5, 0.5, WorldGenerator::ConnectionMethod::MaxDistance);

  return (_world != 0);
}

bool GameCore::destroyWorld() {
  if(!_world) {
    Warn("No world present");
    return false;
  }
  Info("Game tearing down");

  delete _world;
  _world = 0;

  delete _objectManager;
  _objectManager = 0;

  return true;
}

bool GameCore::start() {
  if(_isRunning) {
    Warn("Game is already running");
    return false;
  }

  Info("Game is starting");
  _thinkThread = thread(&GameCore::innerLoop, this);

  _isRunning = true;
  return _isRunning;
}

bool GameCore::stop() {
  if(!_isRunning) {
    Warn("Game is not running");
    return false;
  }

  Info("Game is stopping");
  _isRunning = false;
  _thinkThread.join();

  return (!_isRunning);
}

bool GameCore::isRunning() const { return _isRunning; }

void GameCore::innerLoop() {
  while(_isRunning) {
    sleep(1);
  }
}
