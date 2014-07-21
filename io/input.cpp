#include "io/input.h"

void input_poll(WINDOW* input_window, ClientBase* client) {
  int input = wgetch(input_window);

  Action action;
  switch(input) {
  case 'h': action = MoveWest;  break;
  case 'j': action = MoveSouth; break;
  case 'k': action = MoveNorth; break;
  case 'l': action = MoveEast; break;
  default:
    // If we want to print this sort of stuff, we should really not print non-printable characters
    //Info("KEY_" << (char)input << " pressed");
    action = None;
  }
  send_action(client, action);

	std::this_thread::sleep_for(std::chrono::milliseconds(1));
}

void send_action(ClientBase* client, Action action) {
  switch(action) {
  case MoveNorth:
    client->moveCharacter(IVec2(0, -1));
    break;
  case MoveSouth:
    client->moveCharacter(IVec2(0, 1));
    break;
  case MoveWest:
    client->moveCharacter(IVec2(-1, 0));
    break;
  case MoveEast:
    client->moveCharacter(IVec2(1, 0));
  default:
    Warn("No handler for action " << action);
  }
}
