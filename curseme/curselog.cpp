#include "curseme/curselog.h"
#include <string>
#include <math.h>

// TODO - implement as a ringbuffer of strings in a window, or have errors be popups, etc.

void CurseLog::WriteToChannel(char channel, string str) {
  move(LINES - (log2(channel) + 1), 2);
  addstr(str.c_str());
}