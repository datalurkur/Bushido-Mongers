#include "game/core.h"
#include "world/generator.h"

#include <unistd.h>

GameCore::GameCore(): _objectManager(0), _world(0) {}

GameCore::~GameCore() {
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

void GameCore::update(int elapsed, list<GameEvent>& events) {
  #pragma message "Any activity controlled directly by the core will go here"
}

bool GameCore::isEventVisibleToPlayer(const GameEvent& event, PlayerID player) {
  #pragma message "Perception and area checking will go here"
  return true;
}

bool GameCore::createCharacter(PlayerID player, const string& characterType, BObjectID& characterID) {
  auto playerInfo = _playerMap.find(player);
  if(playerInfo != _playerMap.end()) {
    Error("Player already has an active character");
    return false;
  }
  BObject* character = _objectManager->createObject(characterType);
  if(!character) {
    Error("Failed to create character of type " << characterType);
    return false;
  }
  characterID = character->getID();
  return true;
}

bool GameCore::loadCharacter(PlayerID player, BObjectID& characterID) {
  ASSERT(0, "Character loading not implemented");
  return false;
}

bool GameCore::unloadCharacter(PlayerID player) {
  auto playerInfo = _playerMap.find(player);
  if(playerInfo == _playerMap.end()) {
    Error("Cannot unload player " << player << " - no active character");
    return false;
  }
  #pragma message "Store character data externally for reloading later"
  _objectManager->destroyObject(playerInfo->second);
  _playerMap.erase(playerInfo);
  return true;
}

bool GameCore::isCharacterActive(PlayerID player) {
  auto playerInfo = _playerMap.find(player);
  if(playerInfo == _playerMap.end()) { return false; }
  else { return true; }
}
