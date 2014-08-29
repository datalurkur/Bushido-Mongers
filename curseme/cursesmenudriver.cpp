#include "curseme/cursesmenudriver.h"

CursesMenuDriver::CursesMenuDriver(const string& title, Window* parent): MenuDriver(title, parent), _numItems(0), _items(0), _menu(0) {}

CursesMenuDriver::~CursesMenuDriver() {
  cleanup();
}

size_t CursesMenuDriver::numChoices() const { return _numItems; }

void CursesMenuDriver::cleanup() {
  // Clean up menu if it exists
  if(!_menu) { return; }

  BeginCursesOperation;

  unpost_menu(_menu);
  free_menu(_menu);
  _menu = 0;

  for(size_t i = 0; i < _numItems; ++i) {
    free_item(_items[i]);
  }
  _items = 0;
}

void CursesMenuDriver::redraw(const vector<string>& choices) {
  cleanup();

  if(choices.size() == 0) { return; }
  _numItems = choices.size();

  {
    BeginCursesOperation;
    _items = (ITEM **)calloc(_numItems + 1, sizeof(ITEM *));
    for(size_t i = 0; i < _numItems; i++) {
      _items[i] = new_item(choices[i].c_str(), "");
    }
    _items[_numItems] = (ITEM*)NULL;
    _menu = new_menu(_items);
    set_menu_mark(_menu, Cursor.c_str());
    set_current_item(_menu, _items[_index]);
  }

  _container->attachMenu(_menu);

  {
    BeginCursesOperation;
    post_menu(_menu);
  }

  _container->usableArea()->refresh();
}

void CursesMenuDriver::previousPage() {
  if(!_menu) { return; }
  {
    BeginCursesOperation;
    menu_driver(_menu, REQ_SCR_DPAGE);
  }
  _container->usableArea()->refresh();
}

void CursesMenuDriver::nextPage() {
  if(!_menu) { return; }
  {
    BeginCursesOperation;
    menu_driver(_menu, REQ_SCR_UPAGE);
  }
  _container->usableArea()->refresh();
}

void CursesMenuDriver::onSelectionUpdate() {
  if(!_menu) { return; }
  {
    BeginCursesOperation;
    set_current_item(_menu, _items[_index]);
  }
  _container->usableArea()->refresh();
}
