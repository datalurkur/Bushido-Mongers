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
  TileData,
  TileShrouded,
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

// Sent from server to a specific client to provide information about a tile within an area
// This includes terrain type and visible contents
struct TileDataEvent: public GameEvent {
  IVec2 pos;
  Tile::Type type;

  TileDataEvent(const IVec2& p, Tile::Type t): GameEvent(GameEventType::TileData), pos(p), type(t) {}
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
