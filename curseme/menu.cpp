#include "curseme/menu.h"
#include "curseme/window.h"
#include "util/log.h"

#include <iostream>
#include <string>

// whut.
#define KEY_LLDBENTER 10
#define KEY_REALENTER 13
#define CTRLD   4

Menu::Menu(): _index(0), _title("Make a selection"), _end_on_selection(false)  {}

Menu::Menu(const string& title): _index(0), _title(title), _end_on_selection(false) {}

Menu::Menu(const list<string>& choices): _index(0), _title("Make a selection"), _end_on_selection(false)  {
  for(string choice : choices) { addChoice(choice, ""); }
}
Menu::Menu(const vector<string>& choices): _index(0), _title("Make a selection"), _end_on_selection(false)  {
  for(string choice : choices) { addChoice(choice, ""); }
}

/*
Menu::Menu(vector<string>& choices, vector<string>& descriptions):
	_choices(choices), _descriptions(descriptions) {}
*/

void Menu::setTitle(const string& title) {
  _title = title;
  if(_deployed) {
    teardown();
    setup();
  }
}

void Menu::addChoice(const string& choice) {
  addChoice(choice, "");
}

void Menu::addChoice(const string& choice, const string& description) {
  //_choices.push_back(str_pair(choice, description));
  _choices.push_back(choice);
  _descriptions.push_back(description);
}

//template <typename T>
void Menu::addChoice(const string& choice, function<void()> func) {
  addChoice(choice, "", func);
}

void Menu::addChoice(const string& choice, const string& description, function<void()> func) {
  _choices.push_back(choice);
  _descriptions.push_back(description);

  _functions[choice] = func;
}

void Menu::removeChoice(const string& choice) {
  // FIXME
}

void Menu::setDefaultAction(function<void(string)> func) {
  _def_fun = func;
}

bool Menu::actOnChoice(const string& choice) {
  if(_functions[choice]) {
    Debug("Running action for " << choice);
    _functions[choice]();
    return true;
  } else if(_def_fun) {
    Debug("Running default action for " << choice);
    _def_fun(choice);
    return true;
  }
  return false;
}

// choices without actions /always/ pop the menu from the UIStack;
// if you want this behavior for a choice with an action, set true.
void Menu::setEndOnSelection(bool val) {
  _end_on_selection = val;
}

unsigned int Menu::listen() {
  UIStack::push(this);

  int c;
  while((c = wgetch(menu_win(_menu))) != KEY_F(1)) {
    switch(c) {
      case KEY_DOWN:
        if(_index < _size - 1) {
          menu_driver(_menu, REQ_DOWN_ITEM);
          _index++;
        } else {
          menu_driver(_menu, REQ_FIRST_ITEM);
          _index = 0;
        }
        refresh_window();
        break;
      case KEY_UP:
        if(_index == 0) {
          menu_driver(_menu, REQ_LAST_ITEM);
          _index = _size - 1;
        } else {
          menu_driver(_menu, REQ_UP_ITEM);
          _index--;
        }
        refresh_window();
        break;
        /*
      case KEY_NPAGE:
        menu_driver(_menu, REQ_SCR_DPAGE);
        refresh_window();
        break;
      case KEY_PPAGE:
        menu_driver(_menu, REQ_SCR_UPAGE);
        refresh_window();
        break;
        */
      case KEY_LLDBENTER:
      case KEY_REALENTER: {
        bool acted = actOnChoice(_choices[_index]);

        if(_end_on_selection || !acted) {
          Debug("popping from " << _title << " and returning");
          UIStack::pop();
          return _index; // handle the case outside of Menu using getSelection
        } else {
          // We'll be returning to this menu. Note our location for later.
          set_current_item(_menu, _items[_index]);
        }
        break;
      } default:
        Info("Character pressed: " << c << " (char: " << ((char)c) << ")");
        refresh_window();
        break;
    }
  }

  UIStack::pop();
  return _size;
}

bool Menu::getSelection(unsigned int& index) {
  index = listen();
  Debug("selection " << index << " " << _size);
  return (index != _size);
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

  Info("Deploying Menu " << _title);

  // Create the items and the menu

  if(_choices.size() == 0) {
    // menu.h doesn't like zero-sized menus, so fake it.
    // this permanently adds a <nil> item. If you don't
    // like it you shouldn't deploy an empty menu...
    _choices.push_back("<nil>");
  }
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

  if(_descriptions.size() == 0) {
    menu_opts_off(_menu, O_SHOWDESC);
  }

  // Set menu mark to the string " * "
  set_menu_mark(_menu, " * ");

  // Create the accompanying window
  unsigned long width_needed = 0;
  unsigned long mark_size = string(menu_mark(_menu)).length();

  for(string choice : _choices) {
    if(choice.length() + mark_size > width_needed) {
      width_needed = choice.length() + mark_size;
    }
  }
  if(_title.length() + 1 > width_needed) {
    width_needed = _title.length() + 1;
  }

  //const string title = _title;
  _tb = new TitleBox(stdscr, _size, width_needed, 4, 4, _title);
  _tb->setup();

  /* Set main window and sub window */
  set_menu_win(_menu, _tb->outer_window());
  set_menu_sub(_menu, _tb->window());

  post_menu(_menu);
  refresh_window();
}

void Menu::teardown() {
  if(_deployed) {
    Info("Tearing down Menu " << _title);

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
