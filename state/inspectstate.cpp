#include "state/inspectstate.h"

InspectState::InspectState(LocalBackEnd* client): UIState(stdscr), _client(client) {
  _bindings.insert(make_pair('v', Exit));
  _client->enableCursor(true);
}

InspectState::~InspectState() {
  _client->enableCursor(false);
}

bool InspectState::act(int action) {
  switch(action) {
  case UpLeft:
    _client->moveCursor(IVec2(-1, -1));
    break;
  case Up:
    _client->moveCursor(IVec2(0, -1));
    break;
  case UpRight:
    _client->moveCursor(IVec2(1, -1));
    break;
  case Right:
    _client->moveCursor(IVec2(1, 0));
    break;
  case DownRight:
    _client->moveCursor(IVec2(1, 1));
    break;
  case Down:
    _client->moveCursor(IVec2(0, 1));
    break;
  case DownLeft:
    _client->moveCursor(IVec2(-1, 1));
    break;
  case Left:
    _client->moveCursor(IVec2(-1, 0));
    break;
  case Exit:
    return false;
    break;

  default:
    Warn("No handler for action " << action);
  }

  return true;
}
