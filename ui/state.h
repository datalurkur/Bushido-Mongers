#ifndef UI_STATE_H
#define UI_STATE_H

#include "curseme/curseme.h"

class UIState {
public:
  UIState(WINDOW* window);
  virtual ~UIState();

  bool execute();

  virtual bool operate() = 0;

protected:
  WINDOW* _window;
  UIState* _subState;
};

#endif
