#include "curseme/curseme.h"
#include "curseme/nclog.h"

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

  // Don't echo input
  noecho();

  // Disable cursor
  curs_set(0);

  CurseMe::MainScreenTurnOn();
}

void CurseMeTeardown() {
  endwin();
}

void CurseMe::MainScreenTurnOn() {
  CurseMe::NcursesEnabled = true;
}

bool CurseMe::Enabled() {
  return CurseMe::NcursesEnabled;
}