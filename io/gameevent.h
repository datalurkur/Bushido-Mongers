#ifndef GAMEEVENT_H
#define GAMEEVENT_H

#include "game/bobject.h"
#include "world/tile.h"
#include "world/area.h"
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
  ServerDisconnectedEvent(): GameEvent(ServerDisconnected) {}
};

// Sent from client to server to create a new character
struct CreateCharacterEvent: public GameEvent {
  string name;

  CreateCharacterEvent(const string& n): GameEvent(CreateCharacter), name(n) {}
};

// Sent from client to server to load an existing character
struct LoadCharacterEvent: public GameEvent {
  BObjectID ID;

  LoadCharacterEvent(BObjectID id): GameEvent(LoadCharacter), ID(id) {}
};

// Sent from client to server to unload an active character
struct UnloadCharacterEvent: public GameEvent {
  UnloadCharacterEvent(): GameEvent(UnloadCharacter) {}
};

// Sent from server to indicate that a character was successfully created or loaded
struct CharacterReadyEvent: public GameEvent {
  BObjectID ID;
  CharacterReadyEvent(BObjectID id): GameEvent(CharacterReady), ID(id) {}
};

// Sent from server to indicate that character creation / load failed
struct CharacterNotReadyEvent: public GameEvent {
  string reason;
  CharacterNotReadyEvent(const string& r): GameEvent(CharacterNotReady), reason(r) {}
};

// Sent from server to a specific client to provide basic information about an area
// This includes size, location, name, and connectivity currently visible to the player
struct AreaDataEvent: public GameEvent {
  string name;
  IVec2 pos;
  IVec2 size;

  AreaDataEvent(const string& n, const IVec2& p, const IVec2& s): GameEvent(AreaData),
    name(n), pos(p), size(s) {}
};

// Sent from server to a specific client to indicate that batches of tiles are now either visible or shrouded, with tiles now visible accompanied with timestamps to indicate when they were last changed (so that clients can intelligently cache data)
struct TileDataEvent: public GameEvent {
  struct TileDatum {
    TileType type;
    set<BObjectID> contents;

    TileDatum(TileBase* tile): type(tile->getType()), contents(tile->getContents()) {}
  };

  set<IVec2> shrouded;
  set<IVec2> visible;
  map<IVec2, TileDatum> updated;

  TileDataEvent(Area* a, const set<IVec2>& v):
    GameEvent(TileData) {
    for(auto visible : v) {
      updated.insert(make_pair(visible, TileDatum(a->getTile(visible))));
    }
  }

  TileDataEvent(Area* a, const set<IVec2>& v, const set<IVec2>& u, set<IVec2>&& s):
    GameEvent(TileData), shrouded(s) {
    for(auto nowVisible : v) {
      if(u.find(nowVisible) != u.end()) {
        updated.insert(make_pair(nowVisible, TileDatum(a->getTile(nowVisible))));
      } else {
        visible.insert(nowVisible);
      }
    }
  }
};

// Sent from client in order to move the player's character
struct MoveCharacterEvent: public GameEvent {
  IVec2 dir;

  MoveCharacterEvent(const IVec2& d): GameEvent(MoveCharacter), dir(d) {}
};

struct CharacterMovedEvent: public GameEvent {
  CharacterMovedEvent(): GameEvent(CharacterMoved) {}
};

struct MoveFailedEvent: public GameEvent {
  string reason;

  MoveFailedEvent(const string& r): GameEvent(MoveFailed), reason(r) {}
};

#endif
