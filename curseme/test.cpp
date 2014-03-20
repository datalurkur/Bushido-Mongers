#include <iostream>
#include <string>
#include <curses.h>
#include <menu.h>

using namespace std;

int main(int argc, const char** argv) {
  // Init ncurses
  initscr();

  // Enable keyboard mapping
  keypad(stdscr, TRUE);

  // Don't do line breaks on output
  nonl();

  // Consume input one character at a time (don't wait for newlines)
  cbreak();

  echo();
  // enable cursor
  curs_set(1);

  move(5, 10);

  string line;
  getline(cin, line);

//  int c;
//  while((c = wgetch(stdscr)) != KEY_F(1)) {}

  endwin();
}
