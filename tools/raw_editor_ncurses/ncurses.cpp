#include <stdlib.h>
#include <stdio.h>
#include <signal.h>

#include <menu.h>

void cleanup_curses(int signal) {
  // call free_item for all remaining objects
  endwin();

  exit(signal);
}

void setup_curses() {

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

  // Catch interrupts
  signal(SIGINT, cleanup_curses);
/*
  char text1[] = "Oh give me a clone!\n";
  char text2[] = "Yes a clone of my own!";
  initscr();
  addstr(text1);
  addstr(text2);
  refresh();
  getch();
  endwin();

  exit(0);
*/
  /* add the first string */
  /* add the second string */
  /* display the result */
/* wait */
}

