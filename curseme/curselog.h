#ifndef CURSELOG_H
#define CURSELOG_H

#include <curses.h>
#include <sstream>

using namespace std;

typedef char LogChannel;

class CurseLog {
public:
  static void WriteToChannel(LogChannel channel, string str);
};

#define NCLogToChannel(channel, msg) \
  do { \
    std::stringstream ss; \
    ss << msg; \
    CurseLog::WriteToChannel(channel, ss.str()); \
  } while(false)

#endif
