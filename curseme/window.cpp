#include <string>
#include <curses.h>
#include "curseme/window.h"

Window* Window::StdScr = new Window(stdscr);

Window::Window(WINDOW* win): _win(win) {
  setup();
  //Window::Register();
}

void Window::setup() {
  keypad(_win, TRUE);
  syncok(_win, TRUE);
}

WINDOW* Window::window() {
  return _win;
}

void Window::teardown() {
  delwin(_win);
}

Window::~Window() {
  teardown();
}

TitleBox::TitleBox(WINDOW* outer, string title): _outer(new Window(outer)) {
  setup(title);
}

// Print a border around the main window and print the title.
void TitleBox::setup(string title) {
  int maxy, maxx;
  WINDOW* outer = _outer->window();
  getmaxyx(outer, maxy, maxx);

  _inner = new Window(derwin(outer, 6, maxx - 2, 3, 1));

  box(outer, 0, 0);

  mvwprintw(outer, 1, 2, title.c_str()); // Feel free to make this centered.
  mvwaddch(outer, 2, 0, ACS_LTEE);
  mvwhline(outer, 2, 1, ACS_HLINE, maxx - 2);
  mvwaddch(outer, 2, maxx - 1, ACS_RTEE);
}

void TitleBox::teardown() {
  delete _outer;
  delete _inner;
}

WINDOW* TitleBox::window() {
  return _inner->window();
}

WINDOW* TitleBox::outer_window() {
  return _outer->window();
}
