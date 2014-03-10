#ifndef CURSEME_H
#define CURSEME_H

#include <curses.h>

extern void CurseMeSetup();
extern void CurseMeTeardown();

class CurseMe {
public:
  static void MainScreenTurnOn();
  static bool Enabled();
private:
  static bool NcursesEnabled;
};

#endif
