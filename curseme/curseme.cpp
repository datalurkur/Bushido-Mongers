#include "curseme/curseme.h"
#include "util/log.h"

#include <string>
#include <sstream>

bool CurseMe::Enabled = false;
mutex CurseMe::Mutex;

void CurseMe::Setup() {
  // Init ncurses
  initscr();

  // Enable keyboard mapping
  keypad(stdscr, TRUE);

  // Don't do line breaks on output
  nonl();

  // Consume input one character at a time (don't wait for newlines)
  cbreak();

  // Color!
  start_color();
  init_pair(RED_ON_BLACK,   COLOR_RED,   COLOR_BLACK);
  init_pair(BLUE_ON_BLACK,  COLOR_BLUE,  COLOR_BLACK);
  init_pair(CYAN_ON_BLACK,  COLOR_CYAN,  COLOR_BLACK);
  init_pair(GREEN_ON_BLACK, COLOR_GREEN, COLOR_BLACK);
  init_pair(WHITE_ON_BLACK, COLOR_WHITE, COLOR_BLACK);

  CurseMe::Cursor(false);

  Log::DisableStdout();

  wrefresh(stdscr);

  Enabled = true;
}

void CurseMe::Teardown() {
  Enabled = false;
  Log::EnableStdout();
  endwin();
}

void CurseMe::Cursor(bool state) {
  unique_lock<mutex> Lock(Mutex);

  if(state) {
    echo();
    // enable cursor
    curs_set(1);
  } else {
    // don't echo input
    noecho();
    // disable cursor
    curs_set(0);
  }
}

bool CurseMe::IsEnabled() {
  return Enabled;
}
