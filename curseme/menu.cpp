#include "curseme/menu.h"
#include "curseme/window.h"
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
        refresh_window();
        break;
      case KEY_UP:
        if(index == 0) {
          menu_driver(_menu, REQ_LAST_ITEM);
          index = _size - 1;
        } else {
          menu_driver(_menu, REQ_UP_ITEM);
          index--;
        }
        refresh_window();
        break;
      case KEY_LLVM_ENTER:
      case KEY_REALENTER:
        refresh_window();
        return true;
        break;
      default:
        mvprintw(LINES - 4, 2, "Character pressed is = %3d Hopefully it can be printed as '%c'", c, c);
        refresh_window();
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
  _deployed = true;

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

  // FIXME: NO MAGIC NUMBERS
  _tb = new TitleBox(subwin(stdscr, 10, 40, 4, 4), _title);

  /* Set main window and sub window */
  set_menu_win(_menu, _tb->outer_window());
  set_menu_sub(_menu, _tb->window());

  /* Set menu mark to the string " * " */
  set_menu_mark(_menu, " * ");

  post_menu(_menu);
  refresh_window();
}

void Menu::teardown() {
  unpost_menu(_menu);
  wclear(menu_win(_menu));

  refresh_window();

  // cleanup menu
  free_menu(_menu);

  for(size_t i = 0; i < _size; ++i) {
    free_item(_items[i]);
  }

  delete _tb;

  _deployed = false;
}

void Menu::refresh_window() {
  if(_deployed) {
    wrefresh(menu_win(_menu));
    wrefresh(stdscr);
  }
}

Menu::~Menu() {
  teardown();
}