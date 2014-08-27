#include "ui/state.h"
#include "io/localgameclient.h"

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
  InspectState(LocalGameClient* client);
  virtual ~InspectState();

  bool operate();

private:
  bool act(Action action);

private:
  LocalGameClient* _client;
};
