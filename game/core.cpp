#include "game/core.h"
#include "world/generator.h"
#include "util/geom.h"

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

bool GameCore::createCharacter(PlayerID player, const string& characterType, list<GameEvent>& events) {
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

  // Set up a random character location
  Area* startArea = _world->getRandomArea();
  Tile* startTile = startArea->getRandomEmptyTile();
  character->setLocation(startTile);

  // Send the area information
  events.push_back(AreaDataEvent(startArea->getName(), startArea->getPos(), startArea->getSize()));

  // Send tile information
  set<IVec2> visibleCoords;
  const IVec2* pos = startTile->getCoordinates();
  if(!pos) {
    Error("Failed to get initial coordinates for player; likely location data has become corrupt");
    _objectManager->destroyObject(character->getID());
    return false;
  }
  getViewFrom(player, *pos, visibleCoords);
  for(auto coords : visibleCoords) {
    Tile* tile = startArea->getTile(coords);
    events.push_back(TileDataEvent(coords, tile->getType()));
  }

  return true;
}

bool GameCore::loadCharacter(PlayerID player, BObjectID characterID, list<GameEvent>& events) {
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

void GameCore::getViewFrom(PlayerID player, const IVec2& pos, set<IVec2>& visibleTiles) {
  auto playerInfo = _playerMap.find(player);
  if(playerInfo == _playerMap.end()) {
    Error("Player not active");
    return;
  }
  BObject* playerObject = _objectManager->getObject(playerInfo->second);
  if(!playerObject) {
    Error("Player object not found");
    return;
  }

  BObjectContainer* location = playerObject->getLocation();
  if(!location) {
    Error("Player has no location");
    return;
  }

  Area* area = location->getArea();
  if(!area) {
    Error("Player has a location, but no assigned area; likely, the object location chain is corrupt");
    return;
  }

  // Given the sight radius of a player, cast rays outwards to determine what tiles are visible
  // Hardcode this for now
  int sightRadius = 5;
  // Get the disc of tiles the player could potentially see
  list<IVec2> disc;
  computeRasterizedDisc(sightRadius, disc);

  set<IVec2> visited;
  for(auto relativePoint : disc) {
    IVec2 point = relativePoint + pos;

    if(visited.find(point) != visited.end()) { continue; }

    list<IVec2> lineOfSight;
    computeRasterizedLine(pos, point, lineOfSight);

    bool obstructed = false;
    for(auto pointOnLine : lineOfSight) {
      auto visitedData = visited.insert(pointOnLine);
      if(!obstructed && visitedData.second) {
        visibleTiles.insert(pointOnLine);
      }
      if(!obstructed) {
        // Eventually, this will be *much* more complex
        obstructed = area->getTile(pointOnLine)->getType() != Tile::Type::Wall;
      }
    }
  }
}
