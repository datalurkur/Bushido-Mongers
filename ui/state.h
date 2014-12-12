#ifndef UI_STATE_H
#define UI_STATE_H

#include "curseme/curseme.h"
#include <map>

class UIState {
public:
  enum DefaultBindings {
    None = 0,
    Exit,
    Left,
    Right,
    Up,
    Down,
    UpLeft,
    UpRight,
    DownLeft,
    DownRight,
    NonDefaultBindingsStart
  };

public:
  UIState(WINDOW* window);
  virtual ~UIState();

  bool execute();

protected:
  virtual bool act(int action) = 0;

private:
  bool operate();

protected:
  WINDOW* _window;
  UIState* _subState;

  map<int,int> _bindings;
};

#endif
