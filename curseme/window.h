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

  WINDOW* window();
  void refresh();

public:
  static Window* StdScr;

private:
  WINDOW* _win;
};


// contains a window and subwindow in a box. the user has full reign in the subwindow.
class TitleBox {
public:
	TitleBox(WINDOW* outer, string title);
public:
	void setup(string title);
  void teardown();

  WINDOW* window();
  WINDOW* outer_window();

private:
  Window* _inner;
	Window* _outer;
};

#endif