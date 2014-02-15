#include "game/core.h"

GameCore::GameCore(const string& rawSet) {
  _objectManager = new BObjectManager(rawSet);
}

GameCore::~GameCore() {
  delete _objectManager;
}
