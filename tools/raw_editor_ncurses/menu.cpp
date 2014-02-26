#include <stdlib.h>
#include <stdio.h>
#include <signal.h>

#include <array>
#include <cstdlib>

#include <menu.h>

#include "tools/raw_editor_ncurses/menu.h"

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
}

void cleanup_curses(int signal) {
  // call free_item for all remaining objects
  endwin();

  exit(signal);
}

#define KEY_REALENTER 13
#define CTRLD   4

template <size_t N>
void do_menu_no_desc(std::array<const char *, N> choices) {
  std::array<const char *, choices.size()> descriptions = std::array<const char *, choices.size()>();
  for (auto &x : descriptions) {
    x = "";
  }
  do_menu(choices,  descriptions);
}

template <size_t N>
void do_menu(std::array<const char *, N> choices, std::array<const char *, N> descriptions) {
  // setup menu
  ITEM **my_items;
  MENU *my_menu;

  my_items  = (ITEM **)calloc(choices.size() + 1, sizeof(ITEM *));

  for(size_t i = 0; i < choices.size(); ++i) {
    my_items[i] = new_item(choices[i], descriptions[i]);
  }
  my_items[choices.size()] = (ITEM *)NULL;

  my_menu = new_menu((ITEM **)my_items);
  post_menu(my_menu);
  refresh();

  // menu input
  int c;
  size_t selector = 0;
  while((c = getch()) != KEY_F(1)) {
    switch(c) {
      case KEY_DOWN:
        if(selector < choices.size() - 1) {
          menu_driver(my_menu, REQ_DOWN_ITEM);
          selector++;
        } else {
          menu_driver(my_menu, REQ_FIRST_ITEM);
          selector = 0;
        }
        mvprintw(LINES - 5, 0, "Hovering on option %d", selector);
        break;
      case KEY_UP:
        if(selector == 0) {
          menu_driver(my_menu, REQ_LAST_ITEM);
          selector = choices.size() - 1;
        } else {
          menu_driver(my_menu, REQ_UP_ITEM);
          selector--;
        }
        mvprintw(LINES - 5, 0, "Hovering on option %d", selector);
        break;
      case KEY_REALENTER:
        mvprintw(LINES - 4, 0, "You've selected option %d", selector);
        break;
      default:
        mvprintw(LINES - 4, 0, "Character pressed is = %3d Hopefully it can be printed as '%c'", c, c);
        break;
    }
  }

  // cleanup menu
  for(size_t i = 0; i < choices.size(); ++i) {
    free_item(my_items[i]);
  }

  free_menu(my_menu);
}

int main(int argc, char** argv) {
  // Catch interrupts
  signal(SIGINT, cleanup_curses);

  // Do curses setup
  setup_curses();

  mvprintw(0, 0, "Make a selection");
  do_menu_no_desc( std::array<const char *, 2>{{ "Create New Raw", "Edit Existing Raw" }} );

  // Do curses cleanup
  cleanup_curses(0);
}
