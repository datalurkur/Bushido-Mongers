#ifndef CURSEME_H
#define CURSEME_H

#include "util/assertion.h"

#include <curses.h>
#include <menu.h>
#include <mutex>

using namespace std;

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

  static mutex Mutex;

private:
  static bool Enabled;
};

#define BeginCursesOperation ASSERT(CurseMe::IsEnabled(), "Curses is not enabled"); \
  unique_lock<mutex> Lock(CurseMe::Mutex)

#endif
