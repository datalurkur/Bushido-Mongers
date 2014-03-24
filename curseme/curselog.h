#ifndef CURSELOG_H
#define CURSELOG_H

#include <curses.h>
#include <unordered_map>
#include "curseme/window.h"

using namespace std;

typedef char LogChannel;

class CurseLog {
public:
  static void Setup();
  static void Teardown();

  static void WriteToChannel(LogChannel channel, string str);

private:
  static unordered_map<LogChannel, TitleBox*> boxes;
};

#endif
