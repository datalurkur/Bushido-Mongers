#include <string>
#include <curses.h>
#include "curseme/window.h"
#include "util/log.h"

static Window* StdScr = new Window(stdscr);

Window::Window(WINDOW* win): _win(win) {
  setup();
  //Window::Register();
}

Window::~Window() {
  teardown();
}

void Window::setup() {
  keypad(_win, TRUE);
  syncok(_win, TRUE);
  notimeout(_win,TRUE);
}

WINDOW* Window::window() const {
  return _win;
}

void Window::teardown() {
  delwin(_win);
}


TitleBox* TitleBox::from_parent(WINDOW* parent, int subwin_nlines, int subwin_ncols, int y, int x, const string& title) {
  return new TitleBox(subwin(parent, subwin_nlines + LinePadding, subwin_ncols + ColPadding, y, x), title);
}

TitleBox::TitleBox(WINDOW* outer, const string& title): _outer(new Window(outer)) {
  setup(title);
}

TitleBox::~TitleBox() {
  teardown();
}

// prerequisite: _outer is defined already
// Print a border around the main window and print the title.
void TitleBox::setup(const string& title) {
  int maxy, maxx;
  WINDOW* outer = _outer->window();
  wclear(outer);
  getmaxyx(outer, maxy, maxx);

  _inner = new Window(derwin(outer, maxy - LinePadding, maxx - ColPadding, 3, 1));

  box(outer, 0, 0);

  mvwprintw(outer, 1, 2, title.c_str()); // Feel free to make this centered.
  mvwaddch(outer, 2, 0, ACS_LTEE);
  mvwhline(outer, 2, 1, ACS_HLINE, maxx - 2);
  mvwaddch(outer, 2, maxx - 1, ACS_RTEE);
}

void TitleBox::teardown() {
  wclear(_outer->window());
  delete _outer;
  delete _inner;
}

void TitleBox::refresh() {
  wrefresh(window());
  wrefresh(outer_window());
  wrefresh(stdscr);
}

WINDOW* TitleBox::window() const {
  return _inner->window();
}

WINDOW* TitleBox::outer_window() const {
  return _outer->window();
}

void TitleBox::LogPlacement() {
  int y, x;
  getbegyx(_outer->window(), y, x);
  Info("outer window abs " << y << " " << x);
  getmaxyx(_outer->window(), y, x);
  Info("outer window max " << y << " " << x);

  getbegyx(_inner->window(), y, x);
  Info("inner window abs " << y << " " << x);
  getmaxyx(_inner->window(), y, x);
  Info("inner window max " << y << " " << x);
}
