#include "game/core.h"
#include "world/generator.h"
#include "util/geom.h"
#include "util/structure.h"

#include <unistd.h>

GameCore::GameCore(): _objectManager(0), _world(0) {}

GameCore::~GameCore() {
  for(auto p : _areaObservers) {
    delete p.second;
  }
  destroyWorld();
}

bool GameCore::generateWorld(const string &rawSet) {
  if(_world) {
    Error("World already created");
    return false;
  }
  Info("Game generating");

  _objectManager = new BObjectManager(rawSet);

  // Maybe it'll be interesting in the future to allow tweaks to these parameters, but for now let's just focus on getting a world created with minimal user interaction
  // Just 1 feature for simplicity
  _world = WorldGenerator::GenerateWorld(1, 0.5, 0.5, WorldGenerator::ConnectionMethod::MaxDistance, _objectManager);

  return (_world != 0);
}

bool GameCore::destroyWorld() {
  if(!_world) {
    Warn("No world present");
    return false;
  }
  Info("Game tearing down");

  delete _objectManager;
  _objectManager = 0;

  delete _world;
  _world = 0;

  return true;
}

void GameCore::update(int elapsed, EventMap<PlayerID>& results) {
  #pragma message "Any activity controlled directly by the core will go here"
  // TODO - It will be worth looking into (to keep memory costs down) calling the timedmaps' cleanup functions
}

void GameCore::processPlayerEvent(PlayerID player, GameEvent* event, EventMap<PlayerID>& results) {
  switch(event->type) {
    case CreateCharacter:
      createCharacter(player, "human", results);
      break;
    case LoadCharacter: {
      struct LoadCharacterEvent* e = (struct LoadCharacterEvent*)event;
      loadCharacter(player, e->ID, results);
      break;
    }
    case UnloadCharacter:
      unloadCharacter(player, results);
      break;
    case MoveCharacter:
      moveCharacter(player, ((MoveCharacterEvent*)event)->direction, results);
      break;
    default:
      Warn("Unhandled game event type " << event->type);
      break;
  }
}

void GameCore::createCharacter(PlayerID player, const string& characterType, EventMap<PlayerID>& results) {
  EventQueue* playerResults = results.getEventQueue(player);
  if(isCharacterActive(player)) {
    playerResults->pushEvent(new CharacterNotReadyEvent("Character currently active"));
    return;
  }
  BObject* character = _objectManager->createObjectFromPrototype(characterType);
  if(!character) {
    playerResults->pushEvent(new CharacterNotReadyEvent("Character creation failed"));
    return;
  }

  // Set up a random character location
  Area* startArea = _world->getRandomArea();
  Tile* startTile = startArea->getRandomEmptyTile();
  if(!startTile) {
    playerResults->pushEvent(new CharacterNotReadyEvent("Failed to find start location"));
    _objectManager->destroyObject(character->getID());
    return;
  }
  Debug("Character given initial location " << startTile);
  character->setLocation(startTile);

  // Transfer raw data
  packRaws(playerResults);

  // Set active character
  _playerMap.insert(player, character->getID());
  playerResults->pushEvent(new CharacterReadyEvent(character->getID()));

  // Find out what the player can see
  set<IVec2> visibleCoords;
  getViewFrom(character->getID(), startTile->getCoordinates(), visibleCoords);

  _observers[player] = ObjectObserver(_objectManager);
  _observers[player].areaChanges(startArea, visibleCoords, playerResults);

  // Set up the player as an event observer
  updateObjectAwareness(character->getID());
}

void GameCore::loadCharacter(PlayerID player, BObjectID characterID, EventMap<PlayerID>& results) {
  results.pushEvent(player, new CharacterNotReadyEvent("Character loading not implemented"));
}

void GameCore::unloadCharacter(PlayerID player, EventMap<PlayerID>& results) {
  if(!isCharacterActive(player)) { return; }
  #pragma message "Store character data externally for reloading later"
  BObjectID id = _playerMap.lookup(player);
  objectBecomesUnaware(id);
  _objectManager->destroyObject(id);
  _playerMap.erase(player);
}

void GameCore::moveCharacter(PlayerID player, const IVec2& dir, EventMap<PlayerID>& results) {
  //Debug("Player " << player << "'s character is moving");
  if(!checkCharacterSanity(player)) {
    results.pushEvent(player, new MoveFailedEvent("No active player"));
    return;
  }

  // This will get a little more complicated later when we have jumps / teleports / etc
  if(abs(dir.x) > 1 || abs(dir.y) > 1) {
    results.pushEvent(player, new MoveFailedEvent("Move not legal"));
    return;
  }

  BObjectID characterID = _playerMap.lookup(player);
  BObject* character = _objectManager->getObject(characterID);

  Area* area = character->getLocation()->getArea();
  const IVec2& areaSize = area->getSize();

  // Check the destination coordinates (in-bounds?)
  IVec2 newCoordinates = character->getLocation()->getCoordinates() + dir;
  if(newCoordinates.x < 0 || newCoordinates.y < 0 || newCoordinates.x >= areaSize.x || newCoordinates.y >= areaSize.y) {
    results.pushEvent(player, new MoveFailedEvent("Move out of bounds"));
    return;
  }

  // Check the destination tile type
  Tile* destinationTile = (Tile*)area->getTile(newCoordinates);
  if(!destinationTile) {
    results.pushEvent(player, new MoveFailedEvent("Internal server error - destination tile is null"));
    return;
  }
  if(destinationTile->getType() != TileType::Ground) {
    results.pushEvent(player, new MoveFailedEvent("Movement blocked"));
    return;
  }

  // Move the character
  ThingMovedEvent moveEvent(character->getID(), 0, character->getLocation()->getCoordinates(), newCoordinates);
  Info("Moving character " << character->getID() << " from " << character->getLocation()->getCoordinates() << " to " << newCoordinates);
  character->setLocation(destinationTile);

  // Inform the world
  onEvent(&moveEvent, results);

  // Get the new perspective
  set<IVec2> newView;
  getViewFrom(characterID, newCoordinates, newView);

  // Collect any events that result from the view change
  _observers[player].viewChanges(newView, results.getEventQueue(player));

  // Update at what location the player listens for events
  updateObjectAwareness(characterID);
}

bool GameCore::isCharacterActive(PlayerID player) {
  auto playerInfo = _playerMap.find(player);
  if(playerInfo == _playerMap.end()) { return false; }
  else { return true; }
}

bool GameCore::checkCharacterSanity(PlayerID player) {
  if(!isCharacterActive(player)) { return false; }

  BObject* playerObject = _objectManager->getObject(_playerMap.lookup(player));
  if(!playerObject) {
    Error("Player object not found");
    return false;
  }

  ContainerBase* location = playerObject->getLocation();
  if(!location) {
    Error("Player has no location");
    return false;
  }

  return true;
}

void GameCore::getViewFrom(BObjectID object, const IVec2& pos, set<IVec2>& visibleTiles) {
  // Get the area that the player is in
  Area* area = _objectManager->getObject(object)->getLocation()->getArea();

  // Given the sight radius of a player, cast rays outwards to determine what tiles are visible
  // Hardcode this for now
  int sightRadius = 5;

  auto precomputed = _precomputedSight.find(sightRadius);
  if(precomputed == _precomputedSight.end()) {
    // Get the disc of tiles the player could potentially see
    list<IVec2> disc;
    computeRasterizedDisc(sightRadius, disc);
    _precomputedSight[sightRadius] = disc;
  }

  const IVec2& bounds = area->getSize();
  set<IVec2> visited;
  for(auto relativePoint : _precomputedSight[sightRadius]) {
    IVec2 point = relativePoint + pos;

    if(visited.find(point) != visited.end()) { continue; }

    if(point.x < 0 || point.y < 0 || point.x >= bounds.x || point.y >= bounds.y) {
      continue;
    }

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
        obstructed = area->getTile(pointOnLine)->getType() == TileType::Wall;
      }
    }
  }
  //Info("There are " << visibleTiles.size() << " tiles visible to " << player << " from " << pos);
}

void GameCore::packRaws(EventQueue* results) {
  ostringstream stream(ios_base::binary);
  Raw* raws = _objectManager->getRaws();
  if(!raws->pack(stream)) {
    Error("Failed to pack raws for client");
    return;
  }
  results->pushEvent(new RawDataEvent(stream.str()));
}

QuadTree<BObjectID>* GameCore::getAreaObserverMap(Area* area) {
  auto r = _areaObservers.find(area);
  if(r != _areaObservers.end()) {
    return r->second;
  } else {
    IVec2 areaSize = area->getSize();
    int d = 1;
    int minDim = min(areaSize.x, areaSize.y);
    while(minDim > 16) { minDim >>= 1; d++; }
    return _areaObservers.insert(make_pair(area, new QuadTree<BObjectID>(0, 0, areaSize.x, areaSize.y, d))).first->second;
  }
}

void GameCore::objectBecomesUnaware(BObjectID id) {
  BObject* object = _objectManager->getObject(id);
  ASSERT(object, "Object not found");
  Area* currentArea = object->getLocation()->getArea();
  getAreaObserverMap(currentArea)->removeObject(id);
}

void GameCore::updateObjectAwareness(BObjectID id) {
  BObject* object = _objectManager->getObject(id);
  ASSERT(object, "Object not found");
  Area* currentArea = object->getLocation()->getArea();
  IVec2 areaSize = currentArea->getSize();
  ASSERT(currentArea, "Object area not set");
  QuadTree<BObjectID>* currentAreaMap = getAreaObserverMap(currentArea);
  IVec2 currentPosition = object->getLocation()->getCoordinates();

  #pragma message "Hardcoded sight radii for now"
  int sightRadius = 5;

  int minX = max(0, currentPosition.x - sightRadius),
      minY = max(0, currentPosition.y - sightRadius),
      maxX = min(areaSize.x, currentPosition.x + sightRadius),
      maxY = min(areaSize.y, currentPosition.y + sightRadius);

  currentAreaMap->moveObject(id, minX, minY, maxX, maxY);
}

void GameCore::onEvent(GameEvent* event, EventMap<PlayerID>& results) {
  switch(event->type) {
  case ThingMoved: {
    ThingMovedEvent* e = (ThingMovedEvent*)event;
    BObject* object = _objectManager->getObject(e->object);
    if(!object) {
      Error("Unknown object " << e->object << " moving");
      break;
    }
    Area* affectedArea = object->getLocation()->getArea();
    if(!affectedArea) {
      Error("Object moving through unknown area");
      break;
    }
    IVec2 affectedLocation = object->getLocation()->getCoordinates();
    set<BObjectID> listeners;
    getAreaObserverMap(affectedArea)->findObjects(affectedLocation.x, affectedLocation.y, affectedLocation.x, affectedLocation.y, listeners);
    for(auto listener : listeners) {
      #pragma message "At some point, we should delegate this behavior to an AI module"
      auto playerPair = _playerMap.reverseFind(listener);
      if(playerPair == _playerMap.reverseEnd()) {
        ASSERT(0, "NPCs are unable to process messages currently");
      } else {
        Debug("Event being sent to observer " << playerPair->second);
        results.pushEvent(playerPair->second, event->clone());
        _observers[playerPair->second].objectViewed(e->object, results.getEventQueue(playerPair->second));
      }
    }
  } break;
  default:
    Debug("Unhandled game event type " << event->type);
    break;
  }
}
