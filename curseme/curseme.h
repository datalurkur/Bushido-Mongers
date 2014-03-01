#ifndef CURSEME_H
#define CURSEME_H

#include <curses.h>

extern void CurseMeSetup();
extern void CurseMeTeardown();

class CurseMe {
public:
  CurseMe();
  ~CurseMe();

private:
  void setup();
  void teardown();
};

#endif
