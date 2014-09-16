#ifndef GAMESTATE_H
#define GAMESTATE_H

#include "ui/state.h"
#include "io/localbackend.h"

class GameState: public UIState {
public:
  enum Action {
    None,
    MoveNorth,
    MoveNorthEast,
    MoveEast,
    MoveSouthEast,
    MoveSouth,
    MoveSouthWest,
    MoveWest,
    MoveNorthWest,
    Inspect
  };

public:
  GameState(LocalBackEnd* client);
  virtual ~GameState();

  bool operate();

private:
  bool act(Action action);

private:
  LocalBackEnd* _client;
};

#endif
