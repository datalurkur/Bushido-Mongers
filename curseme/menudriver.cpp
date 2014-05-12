#include "curseme/menudriver.h"

#include <math.h>
using namespace std;

const string MenuDriver::Cursor("->");

MenuDriver::MenuDriver(const string& title, const vector<string>& choices, size_t choicePadding, Window* parent): _numItems(choices.size()), _index(0) {
  size_t width  = 0,
         height = max(_numItems, (size_t)1);

  for(auto choice : choices) {
    width = max(width, choice.size());
  }
  width += (Cursor.size() + choicePadding + 2);
  width = max(width, title.size() + 2);

  _container = new TitleBox(Window::CENTER, (int)width, (int)height, title, parent);
}

MenuDriver::~MenuDriver() {
  delete _container;
}

void MenuDriver::previousItem() {
  if(_index == 0) {
    _index = _numItems - 1;
  } else {
    _index--;
  }
  onSelectionUpdate();
}

void MenuDriver::nextItem() {
  if(_index < _numItems - 1) {
    _index++;
  } else {
    _index = 0;
  }
  onSelectionUpdate();
}

size_t MenuDriver::makeSelection() {
  return _index;
}

size_t MenuDriver::getNumItems() {
  return _numItems;
}

int MenuDriver::getChar() {
  return _container->usableArea()->getChar();
}
