#include "ui/state.h"

UIState::UIState(WINDOW* window): _window(window), _subState(0) {}
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
