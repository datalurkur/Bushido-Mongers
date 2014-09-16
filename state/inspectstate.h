#include "ui/state.h"
#include "io/localbackend.h"

class InspectState: public UIState {
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
    Exit
  };

public:
  InspectState(LocalBackEnd* client);
  virtual ~InspectState();

  bool operate();

private:
  bool act(Action action);

private:
  LocalBackEnd* _client;
};
