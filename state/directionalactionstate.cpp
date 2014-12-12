#include "state/directionalactionstate.h"

DirectionalActionState::DirectionalActionState(LocalBackEnd* client, DirectionalActionState::ActionType type): UIState(stdscr), _client(client), _type(type) {}

DirectionalActionState::~DirectionalActionState() {}

bool DirectionalActionState::act(int action) {
  switch(action) {
  case Exit:
    return false;
    break;
  default:
    Warn("No handler for action " << action);
  }

  return false;
}
