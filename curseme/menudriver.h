#ifndef MENU_DRIVER_H
#define MENU_DRIVER_H

#include "curseme/curseme.h"

#include <vector>
using namespace std;

class Window;
class TitleBox;

class MenuDriver {
public:
  MenuDriver(const string& title, const vector<string>& choices, const string& menuCursor, Window* parent = 0);
  ~MenuDriver();

  int getChar();

  void previousItem();
  void nextItem();

  void previousPage();
  void nextPage();

  size_t makeSelection();

  size_t getNumItems();

private:
  size_t _numItems;
  ITEM** _items;
  MENU* _menu;
  TitleBox* _menuContainer;

  size_t _index;
};

#endif
