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
  AreaData,
  TileData,
  TileShrouded,
};

struct GameEvent {
  GameEventType type;

  GameEvent(GameEventType t): type(t) {}
};

// Sent to the client in the event of a disconnect
struct ServerDisconnected: public GameEvent {
  ServerDisconnected(): GameEvent(GameEventType::ServerDisconnected) {}
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

#endif
