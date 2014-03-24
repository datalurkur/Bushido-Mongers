#include "curseme/curselog.h"
#include "util/log.h"
#include <string>
#include <math.h>

unordered_map<LogChannel, TitleBox*> CurseLog::boxes;

void CurseLog::Setup() {
  CurseLog::boxes[LOG_DEBUG]   = TitleBox::from_parent(stdscr, 1, 40, 1, COLS - 45, "Latest Debug Line");
  CurseLog::boxes[LOG_INFO]    = TitleBox::from_parent(stdscr, 1, 40, 7, COLS - 45, "Latest Info Line");
  CurseLog::boxes[LOG_WARNING] = TitleBox::from_parent(stdscr, 1, 40, 13, COLS - 45, "Latest Warning Line");
  CurseLog::boxes[LOG_ERROR]   = TitleBox::from_parent(stdscr, 1, 40, 19, COLS - 45, "Latest Error Line");
}

void CurseLog::WriteToChannel(char channel, string str) {
  mvwprintw(CurseLog::boxes[channel]->window(), 0, 0, str.c_str());
}