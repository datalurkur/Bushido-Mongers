#include "ui/titlebox.h"

TitleBox::TitleBox(int w, int h, int x, int y, const string& title, Window* parent) {
  _outer = new Window(w + 2, h + 2 + TitleDepth, x, y, parent);
  _outer->setBox();
  _inner = new Window(Window::BOTTOM_CENTER, w, h, 0, 1, _outer);

  setTitle(title);
}

TitleBox::TitleBox(Window::Alignment anchor, float wRatio, float hRatio, const string& title, Window* parent) {
  _outer = new Window(anchor, wRatio, hRatio, 0, 0, parent);
  _outer->setBox();
  _inner = new Window(Window::BOTTOM_CENTER, 1.0f, 1.0f, 2, 2, 0, 1, _outer);

  setTitle(title);
}

TitleBox::TitleBox(Window::Alignment anchor, int w, int h, const string& title, Window* parent) {
  _outer = new Window(anchor, w + 2, h + 2 + TitleDepth, 0, 0, parent);
  _outer->setBox();
  _inner = new Window(Window::BOTTOM_CENTER, w, h, 0, 1, _outer);

  setTitle(title);
}

TitleBox::~TitleBox() {
  delete _inner;
  delete _outer;
}

void TitleBox::setTitle(const string& title) {
  const IVec2& outerDims = _outer->getDims();
  string trimmedTitle = title.substr(0, outerDims.x - 4);
  _outer->printText(2, 1, trimmedTitle.c_str());
  _outer->printChar(0, 2, ACS_LTEE);
  _outer->printHRule(1, 2, ACS_HLINE, outerDims.x - 2);
  _outer->printChar(outerDims.x - 1, 2, ACS_RTEE);
}

void TitleBox::attachMenu(MENU* menu) {
  _outer->setAsMenuWindow(menu);
  _inner->setAsMenuSubwindow(menu);
}

Window* TitleBox::usableArea() const {
  return _inner;
}

void TitleBox::rebuild() {
  _outer->setBox();
}
