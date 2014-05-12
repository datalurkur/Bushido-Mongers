#ifndef CURSES_MENU_DRIVER_H
#define CURSES_MENU_DRIVER_H

#include "curseme/menudriver.h"

class CursesMenuDriver : public MenuDriver {
public:
  CursesMenuDriver(const string& title, const vector<string>& choices, Window* parent = 0);
  virtual ~CursesMenuDriver();

  void previousPage();
  void nextPage();

protected:
  void onSelectionUpdate();

private:
  ITEM** _items;
  MENU* _menu;
};

#endif
