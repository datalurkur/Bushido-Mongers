#ifndef WINDOW_H
#define WINDOW_H

#include <curses.h>

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

private:
  WINDOW* _win;
};


// contains a window and subwindow in a box. the user has full reign in the subwindow.
class TitleBox {
public:
  static TitleBox* from_parent(WINDOW* parent, int subwin_nlines, int subwin_ncols, int y, int x, const string& title);

	TitleBox(WINDOW* outer, const string& title);
public:
	void setup(const string& title);
  void teardown();

  ~TitleBox();

  WINDOW* window() const;
  WINDOW* outer_window() const;

public:
  static const int LinePadding = 4; // top line, title, title line, bottom line.
  static const int ColPadding  = 2; // left column of box, right column of box.

private:
  Window* _inner;
	Window* _outer;
};

#endif