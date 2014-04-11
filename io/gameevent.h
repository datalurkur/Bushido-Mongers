#ifndef GAMEEVENT_H
#define GAMEEVENT_H

#include "game/bobject.h"
#include "world/tile.h"
#include "util/vector.h"

#include <string>

enum GameEventType {
  ServerDisconnected,
  CreateCharacter,
  LoadCharacter,
  UnloadCharacter,
  CharacterReady,
  CharacterNotReady,
  AreaData,
  TileVisible,
  TileShrouded,
  GetTileData,
  TileData,
  DataRestricted,
  MoveCharacter,
  CharacterMoved,
  MoveFailed,
};

struct GameEvent {
  GameEventType type;

  GameEvent(GameEventType t): type(t) {}
};

// Sent to the client in the event of a disconnect
struct ServerDisconnectedEvent: public GameEvent {
  ServerDisconnectedEvent(): GameEvent(GameEventType::ServerDisconnected) {}
};

// Sent from client to server to create a new character
struct CreateCharacterEvent: public GameEvent {
  string name;

  CreateCharacterEvent(const string& n): GameEvent(GameEventType::CreateCharacter), name(n) {}
};

// Sent from client to server to load an existing character
struct LoadCharacterEvent: public GameEvent {
  BObjectID ID;

  LoadCharacterEvent(BObjectID id): GameEvent(GameEventType::LoadCharacter), ID(id) {}
};

// Sent from client to server to unload an active character
struct UnloadCharacterEvent: public GameEvent {
  UnloadCharacterEvent(): GameEvent(GameEventType::UnloadCharacter) {}
};

// Sent from server to indicate that a character was successfully created or loaded
struct CharacterReadyEvent: public GameEvent {
  BObjectID ID;
  CharacterReadyEvent(BObjectID id): GameEvent(GameEventType::CharacterReady), ID(id) {}
};

// Sent from server to indicate that character creation / load failed
struct CharacterNotReadyEvent: public GameEvent {
  string reason;
  CharacterNotReadyEvent(const string& r): GameEvent(GameEventType::CharacterNotReady), reason(r) {}
};

// Sent from server to a specific client to provide basic information about an area
// This includes size, location, name, and connectivity currently visible to the player
struct AreaDataEvent: public GameEvent {
  string name;
  IVec2 pos;
  IVec2 size;

  AreaDataEvent(const string& n, const IVec2& p, const IVec2& s): GameEvent(GameEventType::AreaData),
    name(n), pos(p), size(s) {}
};

// Sent from client to request data about a tile
struct GetTileDataEvent: public GameEvent {
  IVec2 pos;

  GetTileDataEvent(const IVec2& p): GameEvent(GetTileData), pos(p) {}
};

// Sent from server to a specific client to provide information about a tile within an area
// This includes terrain type and visible contents
struct TileDataEvent: public GameEvent {
  IVec2 pos;
  TileType type;
  set<BObjectID> contents;
  time_t lastChanged;

  TileDataEvent(const Tile* tile): GameEvent(GameEventType::TileData),
    pos(tile->getCoordinates()), type(tile->getType()), contents(tile->getContents()),
    lastChanged(tile->lastChanged()) {
    ASSERT(tile, "Source tile must not be null!");
    for(auto c : tile->getContents()) {
      Debug("Source content: " << c);
    }
    for(auto c : contents) {
      Debug("Target content: " << c);
    }
  }
};

// Sent from server to a specific client to indicate that previous data requested was restricted
struct DataRestrictedEvent: public GameEvent {
  string reason;

  DataRestrictedEvent(const string& r): GameEvent(DataRestricted), reason(r) {}
};

// Sned from server to a specific client to indicate that a particular tile is now visible to the player
struct TileVisibleEvent: public GameEvent {
  IVec2 pos;
  time_t lastChanged;

  TileVisibleEvent(const IVec2& p, time_t l): GameEvent(GameEventType::TileVisible), pos(p), lastChanged(l) {}
};

// Sent from server to a specific client to indicate that a particular tile is no longer visible to the player and should not be considered to contain current information (gray it out clientside)
struct TileShroudedEvent: public GameEvent {
  IVec2 pos;

  TileShroudedEvent(const IVec2& p): GameEvent(GameEventType::TileShrouded), pos(p) {}
};

// Sent from client in order to move the player's character
struct MoveCharacterEvent: public GameEvent {
  IVec2 dir;

  MoveCharacterEvent(const IVec2& d): GameEvent(GameEventType::MoveCharacter), dir(d) {}
};

struct CharacterMovedEvent: public GameEvent {
  CharacterMovedEvent(): GameEvent(GameEventType::CharacterMoved) {}
};

struct MoveFailedEvent: public GameEvent {
  string reason;

  MoveFailedEvent(const string& r): GameEvent(GameEventType::MoveFailed), reason(r) {}
};

#endif
