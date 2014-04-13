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


TitleBox::TitleBox(WINDOW* parent, int subwin_nlines, int subwin_ncols, int y, int x, const string& title):
    _parent(parent), _subwin_nlines(subwin_nlines), _subwin_ncols(subwin_ncols), _y(y), _x(x), _title(title), _deployed(false) {}

TitleBox::~TitleBox() {
  teardown();
}

// prerequisite: _outer is defined already
// Print a border around the main window and print the title.
void TitleBox::setup() {
  if(_deployed) { return; }
  Info("Setting up TitleBox " << _title);
  _deployed = true;

  _outer = new Window(subwin(_parent, _subwin_nlines + LinePadding, _subwin_ncols + ColPadding, _y, _x));
  WINDOW* outer = _outer->window();

  _inner = new Window(derwin(outer, _subwin_nlines, _subwin_ncols, 3, 1));

  wclear(outer);
  box(outer, 0, 0);

  int maxy, maxx;
  getmaxyx(outer, maxy, maxx);

  mvwprintw(outer, 1, 2, _title.c_str()); // Feel free to make this centered.
  mvwaddch(outer, 2, 0, ACS_LTEE);
  mvwhline(outer, 2, 1, ACS_HLINE, maxx - 2);
  mvwaddch(outer, 2, maxx - 1, ACS_RTEE);
}

void TitleBox::teardown() {
  if(_deployed) {
    Info("Tearing down TitleBox " << _title);
    _deployed = false;

    wclear(_outer->window());

    delete _outer;
    delete _inner;
  }
}

void TitleBox::refresh() {
  wrefresh(window());
  wrefresh(outer_window());
  wrefresh(stdscr);
}

void TitleBox::clear() {
  wclear(window());
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

PopupRec::PopupRec(const string& message) {
  int maxy, maxx;
  getmaxyx(stdscr, maxy, maxx);

  int topline = maxy / 2 - 1;
  int leftx  = (maxx - message.length()) / 2;

  WINDOW* window = subwin(stdscr, 3, message.length() + 2, topline, leftx);
  box(window, 0, 0);

  mvwprintw(window, 1, 1, message.c_str());

  wgetch(window);
  wclear(window);
  delwin(window);
  refresh();
}