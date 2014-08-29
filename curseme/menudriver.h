#ifndef MENU_DRIVER_H
#define MENU_DRIVER_H

#include "curseme/curseme.h"
#include "ui/titlebox.h"

#include <vector>
using namespace std;

class Window;
class TitleBox;

class MenuDriver {
public:
  MenuDriver(const string& title, Window* parent);
  virtual ~MenuDriver();

  void previousItem();
  void nextItem();

  size_t makeSelection();

  int getChar();

  virtual void previousPage() = 0;
  virtual void nextPage() = 0;

  virtual void redraw(const vector<string>& choices) = 0;
  virtual size_t numChoices() const = 0;

protected:
  virtual void onSelectionUpdate() = 0;

protected:
  static const string Cursor;

protected:
  size_t _index;

  TitleBox* _container;
};

#endif
