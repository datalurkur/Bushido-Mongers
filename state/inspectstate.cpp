#include "state/inspectstate.h"

InspectState::InspectState(LocalGameClient* client): UIState(stdscr), _client(client) {
  _client->enableCursor(true);
}

InspectState::~InspectState() {
  _client->enableCursor(false);
}

bool InspectState::operate() {
  int input = wgetch(_window);

  Action action;
  switch(input) {
  case 'h': action = MoveWest;  break;
  case 'j': action = MoveSouth; break;
  case 'k': action = MoveNorth; break;
  case 'l': action = MoveEast; break;

  case 'u': action = MoveNorthWest; break;
  case 'i': action = MoveNorthEast; break;
  case 'n': action = MoveSouthWest; break;
  case 'm': action = MoveSouthEast; break;

  case KEY_UP:   action = MoveNorth; break;
  case KEY_DOWN: action = MoveSouth; break;
  case KEY_LEFT: action = MoveWest; break;
  case KEY_RIGHT: action = MoveEast; break;

  case 'v': action = Exit; break;

  default:
    if(input > 31 && input != 127) {
      Info("KEY_" << (char)input << " pressed");
    } else {
      Info("KEY_" << input << " pressed");
    }
    action = None;
  }
  return act(action);
}

bool InspectState::act(Action action) {
  switch(action) {
  case MoveNorthWest:
    _client->moveCursor(IVec2(-1, -1));
    break;
  case MoveNorth:
    _client->moveCursor(IVec2(0, -1));
    break;
  case MoveNorthEast:
    _client->moveCursor(IVec2(1, -1));
    break;
  case MoveEast:
    _client->moveCursor(IVec2(1, 0));
    break;
  case MoveSouthEast:
    _client->moveCursor(IVec2(1, 1));
    break;
  case MoveSouth:
    _client->moveCursor(IVec2(0, 1));
    break;
  case MoveSouthWest:
    _client->moveCursor(IVec2(-1, 1));
    break;
  case MoveWest:
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
