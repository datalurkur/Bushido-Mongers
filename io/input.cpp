#include "io/input.h"

void input_poll(WINDOW* input_window, ClientBase* client) {
  int input = wgetch(input_window);

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

  default:
    if(input > 31 && input != 127) {
      Info("KEY_" << (char)input << " pressed");
    } else {
      Info("KEY_" << input << " pressed");
    }
    action = None;
  }
  send_action(client, action);

	std::this_thread::sleep_for(std::chrono::milliseconds(1));
}

void send_action(ClientBase* client, Action action) {
  switch(action) {
  case MoveNorthWest:
    client->moveCharacter(IVec2(-1, -1));
    break;
  case MoveNorth:
    client->moveCharacter(IVec2(0, -1));
    break;
  case MoveNorthEast:
    client->moveCharacter(IVec2(1, -1));
    break;
  case MoveEast:
    client->moveCharacter(IVec2(1, 0));
    break;
  case MoveSouthEast:
    client->moveCharacter(IVec2(1, 1));
    break;
  case MoveSouth:
    client->moveCharacter(IVec2(0, 1));
    break;
  case MoveSouthWest:
    client->moveCharacter(IVec2(-1, 1));
    break;
  case MoveWest:
    client->moveCharacter(IVec2(-1, 0));
    break;

  default:
    Warn("No handler for action " << action);
  }
}
