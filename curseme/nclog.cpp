#include "curseme/nclog.h"

bool NCLog::NcursesEnabled = false;

void NCLog::EnableNcurses() {
  NcursesEnabled = true;
}

bool NCLog::NcursesOn() {
  return NcursesEnabled;
}
