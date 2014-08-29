#ifndef CURSES_MENU_DRIVER_H
#define CURSES_MENU_DRIVER_H

#include "curseme/menudriver.h"

class CursesMenuDriver : public MenuDriver {
public:
  CursesMenuDriver(const string& title, Window* parent = 0);
  virtual ~CursesMenuDriver();

  void previousPage();
  void nextPage();

  size_t numChoices() const;
  void redraw(const vector<string>& choices);

protected:
  void onSelectionUpdate();

private:
  void cleanup();

private:
  size_t _numItems;
  ITEM** _items;
  MENU* _menu;
};

#endif
