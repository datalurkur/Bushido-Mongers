#include "state/gamestate.h"
#include "state/inspectstate.h"

GameState::GameState(LocalBackEnd* client): UIState(stdscr), _client(client) {
}

GameState::~GameState() {
}

bool GameState::operate() {
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

  case 'v': action = Inspect; break;

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

bool GameState::act(Action action) {
  switch(action) {
  case MoveNorthWest:
    return _client->sendToServer(new MoveCharacterEvent(IVec2(-1, -1)));
  case MoveNorth:
    return _client->sendToServer(new MoveCharacterEvent(IVec2( 0, -1)));
  case MoveNorthEast:
    return _client->sendToServer(new MoveCharacterEvent(IVec2( 1, -1)));
  case MoveEast:
    return _client->sendToServer(new MoveCharacterEvent(IVec2( 1,  0)));
  case MoveSouthEast:
    return _client->sendToServer(new MoveCharacterEvent(IVec2( 1,  1)));
  case MoveSouth:
    return _client->sendToServer(new MoveCharacterEvent(IVec2( 0,  1)));
  case MoveSouthWest:
    return _client->sendToServer(new MoveCharacterEvent(IVec2(-1,  1)));
  case MoveWest:
    return _client->sendToServer(new MoveCharacterEvent(IVec2(-1,  0)));
  case Inspect:
    _subState = new InspectState(_client);
    return true;
  default:
    Error("No handler for action " << action);
    return true;
  }
}
