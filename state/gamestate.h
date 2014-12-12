#ifndef GAMESTATE_H
#define GAMESTATE_H

#include "ui/state.h"
#include "io/localbackend.h"

class GameState: public UIState {
public:
  enum Action {
    Inspect = NonDefaultBindingsStart,
    Attack
  };

public:
  GameState(LocalBackEnd* client);
  virtual ~GameState();

protected:
  bool act(int action);

private:
  LocalBackEnd* _client;
};

#endif
