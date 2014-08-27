#ifndef GAMESTATE_H
#define GAMESTATE_H

#include "ui/state.h"
#include "io/localgameclient.h"

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
  GameState(LocalGameClient* client);
  virtual ~GameState();

  bool operate();

private:
  bool act(Action action);

private:
  LocalGameClient* _client;
};

#endif
