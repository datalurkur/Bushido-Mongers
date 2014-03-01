#include <stdlib.h>

#include <vector>
#include <string>
#include <cstdlib>

#include <menu.h>

#include "curseme/menu.h"

#define KEY_REALENTER 13
#define CTRLD         4

Menu::Menu(const vector<string>& choices) {
  _choices = new vector<string>(choices);
  _descriptions = new vector<string>(choices.size(), "");
  setup();
}

Menu::Menu(const vector<string>& choices, const vector<string>& descriptions) {
  if(choices.size() != descriptions.size()) {
    throw SizeMismatchException();
  }
  _choices = new vector<string>(choices);
  _descriptions = new vector<string>(descriptions);
  setup();
}

Menu::~Menu() {
  teardown();
  delete _choices;
  delete _descriptions;
}

void Menu::setup() {
  _items = (ITEM**)calloc(_choices->size() + 1, sizeof(ITEM*));
  for(size_t i = 0; i < _choices->size(); ++i) {
    _items[i] = new_item((*_choices)[i].c_str(), (*_descriptions)[i].c_str());
  }
  _items[_choices->size()] = (ITEM*)NULL;

  _menu = new_menu((ITEM**)_items);
}

void Menu::teardown() {
  free_menu(_menu);

  for(size_t i = 0; i < _choices->size(); ++i) {
    free_item(_items[i]);
  }
}

void Menu::prompt() {
  post_menu(_menu);
  refresh();

  // menu input
  int c;
  size_t selector = 0;
  while((c = getch()) != KEY_F(1)) {
    switch(c) {
      case KEY_DOWN:
        if(selector < _choices->size() - 1) {
          menu_driver(_menu, REQ_DOWN_ITEM);
          selector++;
        } else {
          menu_driver(_menu, REQ_FIRST_ITEM);
          selector = 0;
        }
        mvprintw(LINES - 5, 0, "Hovering on option %d", selector);
        break;
      case KEY_UP:
        if(selector == 0) {
          menu_driver(_menu, REQ_LAST_ITEM);
          selector = _choices->size() - 1;
        } else {
          menu_driver(_menu, REQ_UP_ITEM);
          selector--;
        }
        mvprintw(LINES - 5, 0, "Hovering on option %d", selector);
        break;
      case KEY_REALENTER:
        mvprintw(LINES - 4, 0, "You've selected option %d", selector);
        break;
      default:
        mvprintw(LINES - 4, 0, "Character pressed is = %3d Hopefully it can be printed as '%c'", c, c);
        break;
    }
  }
}
