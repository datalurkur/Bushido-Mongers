#ifndef CURSEME_H
#define CURSEME_H

#include <curses.h>

extern void CurseMeSetup();
extern void CurseMeTeardown();

class CurseMe {
public:
  static void MainScreenTurnOn();
  static bool Enabled();
  static void Cursor(bool state);
private:
  static bool NcursesEnabled;
};

#define NCLogToChannel(channel, msg) \
  do { \
    std::stringstream ss; \
    ss << msg; \
    mvprintw(LINES - 1, 2, "%s", ss.str().c_str()); \
  } while(false)

#endif
