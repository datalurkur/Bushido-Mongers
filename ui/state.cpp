#include "ui/state.h"

UIState::UIState(WINDOW* window): _window(window), _subState(0) {
  _bindings.insert(make_pair('h', Left));
  _bindings.insert(make_pair('j', Down));
  _bindings.insert(make_pair('k', Up));
  _bindings.insert(make_pair('l', Right));
  _bindings.insert(make_pair(KEY_LEFT, Left));
  _bindings.insert(make_pair(KEY_DOWN, Down));
  _bindings.insert(make_pair(KEY_UP, Down));
  _bindings.insert(make_pair(KEY_RIGHT, Down));
  _bindings.insert(make_pair('u', UpLeft));
  _bindings.insert(make_pair('i', UpRight));
  _bindings.insert(make_pair('n', DownLeft));
  _bindings.insert(make_pair('m', DownRight));
  _bindings.insert(make_pair(27, Exit));
}

UIState::~UIState() {}

bool UIState::execute() {
  if(_subState) {
    // In the future, we might consider the possibility of a deep bail-out (ie 3 substate layers deep, we have a shortcut for exiting the game), at which point this would need to return a result of some kind rather than a boolean
    if(!_subState->execute()) {
      delete _subState;
      _subState = 0;
    }
    return true;
  } else {
    return operate();
  }
}

bool UIState::operate() {
  int input = wgetch(_window);
  auto mapItr = _bindings.find(input);
  if(mapItr == _bindings.end()) {
    return act(None);
  } else {
    return act(mapItr->second);
  }
}
