#include <stdlib.h>
#include <stdio.h>
#include <signal.h>
#include <curses.h>

void setup() {

  // Init ncurses
  initscr();

  // Enable keyboard mapping
  keypad(stdscr, TRUE);

  // Don't do line breaks on output
  nonl();

  // Consume input one character at a time (don't wait for newlines)
  cbreak();

  // Echo input
  echo();
}

void cleanup(int signal) {
  endwin();

  exit(signal);
}

int main(int argc, char** argv) {
  // Catch interrupts
  signal(SIGINT, cleanup);

  // Do curses setup
  setup();

  // Do ncurses stuff
  // CODE ME

  // Do curses cleanup
  cleanup(0);
}
