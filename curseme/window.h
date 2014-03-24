#ifndef WINDOW_H
#define WINDOW_H

#include <curses.h>
#include <string>
#include "curseme/uistack.h"

using namespace std;

class Window {
public:
  Window(WINDOW* win);

public:
  ~Window();

public:
  void setup();
  void teardown();

  WINDOW* window() const;
  void refresh();

  static Window* StdScr;

private:
  WINDOW* _win;
};


// contains a window and subwindow in a box. the user has full reign in the subwindow.
class TitleBox : public UIE {
public:
  TitleBox(WINDOW* parent, int subwin_nlines, int subwin_ncols, int y, int x, const string& title);
  ~TitleBox();

public:
	void setup();
  void teardown();

  void refresh();

  WINDOW* window() const;
  WINDOW* outer_window() const;

private:
  void LogPlacement();

  static const int LinePadding = 4; // top line, title, title line, bottom line.
  static const int ColPadding  = 2; // left column of box, right column of box.

private:
  WINDOW* _parent;
  Window* _inner;
	Window* _outer;

  int _subwin_nlines;
  int _subwin_ncols;
  int _y;
  int _x;

  string _title;
};

#endif