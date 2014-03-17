#ifndef NCLOG_H
#define NCLOG_H

#include <curses.h>
#include <string>
#include <sstream>

#define NCLogToChannel(channel, msg) \
  do { \
    std::stringstream ss; \
    ss << msg << "\n"; \
    mvprintw(LINES - 1, 0, "%s", ss.str().c_str()); \
  } while(false)

#endif
