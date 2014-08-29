#ifndef TITLEBOX_H
#define TITLEBOX_H

#include "curseme/window.h"

// Contains a window and subwindow in a box. the user has full reign in the subwindow.
class TitleBox {
public:
  TitleBox(int w, int h, int x, int y, const string& title, Window* parent = 0);
  TitleBox(Window::Alignment anchor, float wRatio, float hRatio, const string& title, Window* parent = 0);
  TitleBox(Window::Alignment anchor, int w, int h, const string& title, Window* parent = 0);
  virtual ~TitleBox();

  Window* usableArea() const;

  void setTitle(const string& title);
  void attachMenu(MENU* menu);

private:
  // One line for the title, one line for the horizontal rule
  static const int TitleDepth = 2;

private:
  Window* _inner;
	Window* _outer;
};

#endif
