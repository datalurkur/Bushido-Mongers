#include "curseme/menudriver.h"

#include <math.h>
using namespace std;

const string MenuDriver::Cursor("->");

MenuDriver::MenuDriver(const string& title, Window* parent): _index(0) {
  _container = new TitleBox(Window::CENTER, 1.0f, 1.0f, title, parent);
}

MenuDriver::~MenuDriver() {
  delete _container;
}

void MenuDriver::previousItem() {
  if(_index == 0) {
    _index = numChoices() - 1;
  } else {
    _index--;
  }
  onSelectionUpdate();
}

void MenuDriver::nextItem() {
  if(_index < numChoices() - 1) {
    _index++;
  } else {
    _index = 0;
  }
  onSelectionUpdate();
}

size_t MenuDriver::makeSelection() {
  return _index;
}

int MenuDriver::getChar() {
  return _container->usableArea()->getChar();
}
