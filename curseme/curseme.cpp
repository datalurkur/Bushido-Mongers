#include "curseme/curseme.h"
#include "util/log.h"

#include <string>
#include <sstream>

bool CurseMe::NcursesEnabled = false;

void CurseMeSetup() {
  // Init ncurses
  initscr();

  // Enable keyboard mapping
  keypad(stdscr, TRUE);

  // Don't do line breaks on output
  nonl();

  // Consume input one character at a time (don't wait for newlines)
  cbreak();

  CurseMe::Cursor(false);

  CurseMe::MainScreenTurnOn();

  Log::DisableStdout();
  CurseLog::Setup();
}

void CurseMeTeardown() {
  Log::EnableStdout();

  endwin();
}

void CurseMe::Cursor(bool state) {
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

void CurseMe::MainScreenTurnOn() {
  CurseMe::NcursesEnabled = true;
}

bool CurseMe::Enabled() {
  return CurseMe::NcursesEnabled;
}
