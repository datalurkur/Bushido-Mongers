#include "curseme/menudriver.h"
#include "ui/titlebox.h"

#include <math.h>

MenuDriver::MenuDriver(const string& title, const vector<string>& choices, const string& menuCursor, Window* parent): _numItems(0), _items(0), _menu(0), _menuContainer(0), _index(0) {
  _numItems = choices.size();

  unsigned long maxChoiceLength = 0;
  if(_numItems > 0) {
    BeginCursesOperation;

    _items = (ITEM **)calloc(_numItems + 1, sizeof(ITEM *));
    for(size_t i = 0; i < choices.size(); i++) {
      _items[i] = new_item(choices[i].c_str(), "");
      maxChoiceLength = max(maxChoiceLength, choices[i].size());
    }
    maxChoiceLength += menuCursor.size() + 1;
    _items[_numItems] = (ITEM*)NULL;
    _menu = new_menu(_items);

    set_menu_mark(_menu, menuCursor.c_str());
    set_current_item(_menu, _items[_index]);
  }

  maxChoiceLength = max(maxChoiceLength, title.size() + 1);

  _menuContainer = new TitleBox(maxChoiceLength, max((size_t)1, _numItems), 4, 4, title, parent);
  _menuContainer->attachMenu(_menu);

  if(_numItems > 0) {
    BeginCursesOperation;
    // and finally set the selection position before posting
    post_menu(_menu);
  }

  _menuContainer->refresh();
}

MenuDriver::~MenuDriver() {
  if(!_menuContainer) { return; }

  if(_menu) {
    BeginCursesOperation;
    unpost_menu(_menu);
  }

  delete _menuContainer;
  _menuContainer = 0;

  if(_menu) {
    BeginCursesOperation;
    // cleanup menu
    free_menu(_menu);
    _menu = 0;

    for(size_t i = 0; i < _numItems; ++i) {
      free_item(_items[i]);
    }
    _items = 0;
  }
}

int MenuDriver::getChar() {
  return _menuContainer->getChar();
}

void MenuDriver::previousItem() {
  if(!_menu) { return; }

  if(_index == 0) {
    BeginCursesOperation;
    menu_driver(_menu, REQ_LAST_ITEM);
    _index = _numItems - 1;
  } else {
    BeginCursesOperation;
    menu_driver(_menu, REQ_UP_ITEM);
    _index--;
  }
  _menuContainer->refresh();
}

void MenuDriver::nextItem() {
  if(!_menu) { return; }

  if(_index < _numItems - 1) {
    BeginCursesOperation;
    menu_driver(_menu, REQ_DOWN_ITEM);
    _index++;
  } else {
    BeginCursesOperation;
    menu_driver(_menu, REQ_FIRST_ITEM);
    _index = 0;
  }
  _menuContainer->refresh();
}

void MenuDriver::previousPage() {
  if(!_menu) { return; }

  {
    BeginCursesOperation;
    menu_driver(_menu, REQ_SCR_DPAGE);
  }
  _menuContainer->refresh();
}

void MenuDriver::nextPage() {
  if(!_menu) { return; }

  {
    BeginCursesOperation;
    menu_driver(_menu, REQ_SCR_UPAGE);
  }
  _menuContainer->refresh();
}

size_t MenuDriver::makeSelection() {
  return _index;
}

size_t MenuDriver::getNumItems() {
  return _numItems;
}
