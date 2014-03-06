#ifndef NCLOG_H
#define NCLOG_H

#include <string>
#include <sstream>

#include <curses.h>
#include "util/log.h"

class PrintingRingBuffer

#undef LogToChannel
#define LogToChannel(channel, msg) \
  do { \
    if(Log::IsChannelEnabled(channel)) { \
	  std::stringstream ss; \
	  ss << msg << "\n"; \
      mvprintw(LINES - 2, 0, "%s", ss.str().c_str()); \
    } \
  } while(false)

#endif