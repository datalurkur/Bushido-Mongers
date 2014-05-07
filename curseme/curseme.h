#ifndef CURSEME_H
#define CURSEME_H

#include <curses.h>

enum {
  RED_ON_BLACK = 1,
  BLUE_ON_BLACK,
  CYAN_ON_BLACK,
  GREEN_ON_BLACK,
  WHITE_ON_BLACK
};

class CurseMe {
public:
  static void Setup();
  static void Teardown();
  static bool IsEnabled();
  static void Cursor(bool state);

private:
  static bool Enabled;
};

#endif
