#include "curseme/window.h"
#include "util/log.h"

#include <string>
#include <math.h>

Window::Window(int w, int h, int x, int y, Window* parent): _parent(parent) {
  setupWindow(w, h, x, y);
}

Window::Window(Alignment anchor, float wRatio, float hRatio, int wPad, int hPad, int xPad, int yPad, Window* parent): _parent(parent) {
  int mW, mH, x, y;
  determineMaxDimensions(mW, mH);

  int w = max(min(mW, (int)(mW * wRatio) - wPad - xPad), 1),
      h = max(min(mH, (int)(mH * hRatio) - hPad - yPad), 1);

  determineCoordinates(anchor, mW, mH, xPad, yPad,  w, h, x, y);
  setupWindow(w, h, x, y);
}

Window::Window(Alignment anchor, int w, int h, int xPad, int yPad, Window* parent): _parent(parent) {
  int mW, mH, x, y;
  determineMaxDimensions(mW, mH);
  determineCoordinates(anchor, mW, mH, xPad, yPad, w, h, x, y);
  setupWindow(w, h, x, y);
}

Window::~Window() {
  {
    BeginCursesOperation;
    wclear(_win);
    wrefresh(_win);
    delwin(_win);
  }
  if(_parent) {
    _parent->refresh();
  } else {
    BeginCursesOperation;
    wrefresh(stdscr);
  }
}

void Window::determineMaxDimensions(int& mW, int& mH) {
  if(_parent) {
    IVec2 maxDims = _parent->getDims();
    mW = maxDims.x;
    mH = maxDims.y;
  } else {
    getmaxyx(stdscr, mH, mW);
  }
}

void Window::determineCoordinates(Alignment anchor, int mW, int mH, int xPad, int yPad, int w, int h, int& x, int& y) {
  x = xPad;
  y = yPad;

  switch(anchor) {
    case BOTTOM_LEFT:
    case BOTTOM_CENTER:
    case BOTTOM_RIGHT:
      y = mH - h - yPad;
      break;
    case CENTER_LEFT:
    case CENTER:
    case CENTER_RIGHT:
      y = (mH - h - yPad) / 2;
      break;
    default:
      break;
  }
  switch(anchor) {
    case BOTTOM_CENTER:
    case CENTER:
    case TOP_CENTER:
      x = (mW - w - xPad) / 2;
      break;
    case BOTTOM_RIGHT:
    case CENTER_RIGHT:
    case TOP_RIGHT:
      x = mW - w - xPad;
      break;
    default:
      break;
  }
}

void Window::setupWindow(int w, int h, int x, int y) {

  if(_parent) {
    _win = _parent->createSubWindow(w, h, x, y);
  } else {
    BeginCursesOperation;
    _win = newwin(h, w, y, x);
  }

  _dims = IVec2(w, h);

  {
    BeginCursesOperation;
    keypad(_win, TRUE);
    syncok(_win, TRUE);
    notimeout(_win, TRUE);
  }

  clear();
  refresh();
}

const IVec2& Window::getDims() const {
  return _dims;
}

void Window::refresh() {
  BeginCursesOperation;
  wrefresh(_win);
}

void Window::clear() {
  BeginCursesOperation;
  wclear(_win);
}

void Window::setBox() {
  BeginCursesOperation;
  box(_win, 0, 0);
  wrefresh(_win);
}

void Window::setAsMenuWindow(MENU* menu) {
  BeginCursesOperation;
  set_menu_win(menu, _win);
}

void Window::setAsMenuSubwindow(MENU* menu) {
  BeginCursesOperation;
  set_menu_sub(menu, _win);
}

void Window::setCursorPosition(int x, int y) {
  BeginCursesOperation;

  //wmove(_win, x, y);
  // TODO - determine why wmove(tb->window(), 0, 0) doesn't always work (sometimes y is off-by-one)
  int dY, dX;
  getbegyx(_win, dY, dX);
  wmove(stdscr, y + dY, x + dX);

  wrefresh(_win);
}

void Window::printText(int x, int y, const char* fmt, ...) {
  BeginCursesOperation;
  va_list v;
  va_start(v, fmt);
  mvwprintw(_win, y, x, fmt, v);
  va_end(v);
  wrefresh(_win);
}

void Window::printChar(int x, int y, const chtype c) {
  BeginCursesOperation;
  mvwaddch(_win, y, x, c);
  wrefresh(_win);
}

void Window::printHRule(int x, int y, chtype c, int n) {
  BeginCursesOperation;
  mvwhline(_win, y, x, c, n);
  wrefresh(_win);
}

int Window::getChar() {
  BeginCursesOperation;
  return wgetch(_win);
}

int Window::getString(string& str) {
  BeginCursesOperation;
  char buffer[256];
  int ret = wgetnstr(_win, buffer, sizeof(buffer) - 1);
  if(ret == OK) {
    str = string(buffer);
  }
  return ret;
}

WINDOW* Window::createSubWindow(int w, int h, int dX, int dY) {
  BeginCursesOperation;
  return derwin(_win, h, w, dY, dX);
}
