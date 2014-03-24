#include "curseme/curselog.h"
#include "util/log.h"
#include <string>
#include <math.h>

unordered_map<LogChannel, TitleBox*> CurseLog::boxes;

void CurseLog::Setup() {
  CurseLog::boxes[LOG_DEBUG]   = new TitleBox(stdscr, 1, 40, 1, COLS - 45, "Latest Debug Line");
  CurseLog::boxes[LOG_INFO]    = new TitleBox(stdscr, 1, 40, 7, COLS - 45, "Latest Info Line");
  CurseLog::boxes[LOG_WARNING] = new TitleBox(stdscr, 1, 40, 13, COLS - 45, "Latest Warning Line");
  CurseLog::boxes[LOG_ERROR]   = new TitleBox(stdscr, 1, 40, 19, COLS - 45, "Latest Error Line");
}

void CurseLog::WriteToChannel(char channel, string str) {
  WINDOW* window = CurseLog::boxes[channel]->window();
  wclear(window);
  mvwprintw(window, 0, 0, str.c_str());
}