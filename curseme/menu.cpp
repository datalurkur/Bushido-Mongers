#include "curseme/menu.h"
#include "curseme/nclog.h"
#include "util/log.h"

#include <iostream>
#include <string>

#define KEY_LLVM_ENTER 10
#define KEY_REALENTER 13
#define CTRLD   4

Menu::Menu(): _deployed(false), _title("Make a selection") {}

Menu::Menu(const string& title): _deployed(false), _title(title) {}

//Menu::Menu(const vector<string>& choices): _deployed(false), _choices(choices), _title("Make a selection") {

Menu::Menu(const list<string>& choices): _deployed(false), _title("Make a selection") {
  for(string choice : choices) { _choices.push_back(choice); }
  setup();
  menu_opts_off(_menu, O_SHOWDESC);
}

/*
Menu::Menu(vector<string>& choices, vector<string>& descriptions):
	_choices(choices), _descriptions(descriptions) {}
*/

void Menu::setTitle(const string& title) { _title = title; }

void Menu::addChoice(const string& choice) {
  addChoice(choice, "");
}

void Menu::addChoice(const string& choice, const string& description) {
	_choices.push_back(choice);
	_descriptions.push_back(description);
}
//void Menu::addChoice(string& choice, string& description, function<int> func) {}

bool Menu::getSelection(unsigned int& index) {
  // draw the menu if it's not already drawn
  if(!_deployed) { setup(); }
  // menu input
  int c;
  index = 0;

  while((c = wgetch(menu_win(_menu))) != KEY_F(1)) {
    switch(c) {
      case KEY_DOWN:
        if(index < _size - 1) {
          menu_driver(_menu, REQ_DOWN_ITEM);
          index++;
        } else {
          menu_driver(_menu, REQ_FIRST_ITEM);
          index = 0;
        }
        mvprintw(LINES - 5, 0, "Hovering on option %d", index);
        break;
      case KEY_UP:
        if(index == 0) {
          menu_driver(_menu, REQ_LAST_ITEM);
          index = _size - 1;
        } else {
          menu_driver(_menu, REQ_UP_ITEM);
          index--;
        }
        mvprintw(LINES - 5, 0, "Hovering on option %d", index);
        break;
      case KEY_LLVM_ENTER:
      case KEY_REALENTER:
        mvprintw(LINES - 4, 0, "You've selected option %d", index);
        return true;
        break;
      default:
        mvprintw(LINES - 4, 0, "Character pressed is = %3d Hopefully it can be printed as '%c'", c, c);
        break;
    }
  }
  return false;
}

bool Menu::getChoice(string& choice) {
  unsigned int index;
  if(getSelection(index)) {
    choice = _choices[index];
    return true;
  } else {
    return false;
  }
}

void Menu::setup() {
  if(_deployed) { return; }

  // Create the items and the menu

  _size  = _choices.size();
  _items = (ITEM **)calloc(_size + 1, sizeof(ITEM *));

  for(size_t i = 0; i < _size; ++i) {
    if(i < _descriptions.size()) {
      _items[i] = new_item(_choices[i].c_str(), _descriptions[i].c_str());
    } else {
      _items[i] = new_item(_choices[i].c_str(), "");
    }
  }
  _items[_size] = (ITEM *)NULL;

  _menu = new_menu((ITEM **)_items);

  // Create the accompanying window

  WINDOW* _win = newwin(10, 40, 4, 4);
  keypad(_win, TRUE);

  /* Set main window and sub window */
  set_menu_win(_menu, _win);
  set_menu_sub(_menu, derwin(_win, 6, 38, 3, 1));

  /* Set menu mark to the string " * " */
  set_menu_mark(_menu, " * ");

  // Print a border around the main window and print a title

  box(_win, 0, 0);

  mvwprintw(_win, 1, 2, _title.c_str());
  mvwaddch(_win, 2, 0, ACS_LTEE);
  mvwhline(_win, 2, 1, ACS_HLINE, 38);
  mvwaddch(_win, 2, 39, ACS_RTEE);

  post_menu(_menu);
  wrefresh(_win);

  _deployed = true;
}

void Menu::teardown() {
  unpost_menu(_menu);

  // cleanup menu
  for(size_t i = 0; i < _size; ++i) {
    free_item(_items[i]);
  }

  free_menu(_menu);

  delwin(menu_win(_menu));
  delwin(menu_sub(_menu));

  refresh();

  _deployed = false;
}

Menu::~Menu() {
  teardown();
}