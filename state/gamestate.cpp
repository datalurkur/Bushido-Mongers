#include "state/gamestate.h"
#include "state/inspectstate.h"
#include "state/directionalactionstate.h"

GameState::GameState(LocalBackEnd* client): UIState(stdscr), _client(client) {
  _bindings.insert(make_pair('v', Action::Inspect));
  _bindings.insert(make_pair('a', Action::Attack));
}

GameState::~GameState() {
}

bool GameState::act(int action) {
  switch(action) {
  case UpLeft:
    return _client->sendToServer(new MoveCharacterEvent(IVec2(-1, -1)));
  case Up:
    return _client->sendToServer(new MoveCharacterEvent(IVec2( 0, -1)));
  case UpRight:
    return _client->sendToServer(new MoveCharacterEvent(IVec2( 1, -1)));
  case Right:
    return _client->sendToServer(new MoveCharacterEvent(IVec2( 1,  0)));
  case DownRight:
    return _client->sendToServer(new MoveCharacterEvent(IVec2( 1,  1)));
  case Down:
    return _client->sendToServer(new MoveCharacterEvent(IVec2( 0,  1)));
  case DownLeft:
    return _client->sendToServer(new MoveCharacterEvent(IVec2(-1,  1)));
  case Left:
    return _client->sendToServer(new MoveCharacterEvent(IVec2(-1,  0)));
  case Inspect:
    _subState = new InspectState(_client);
    return true;
  case Attack:
    _subState = new DirectionalActionState(_client, DirectionalActionState::ActionType::Attack);
    return true;
  default:
    Error("No handler for action " << action);
    return true;
  }
}
