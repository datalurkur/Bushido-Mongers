#include "ui/menu.h"
#include "curseme/hotkeymenudriver.h"
#include "util/log.h"

#include <iostream>
#include <algorithm>
#include <string>

// whut.
#define KEY_LLDBENTER 10
#define KEY_REALENTER 13
#define CTRLD   4

// ============= MENU BASE ===============
MenuBase::MenuBase(const string& title, Window* window): _title(title), _window(window) {
  _driver = new HotkeyMenuDriver(_title, _window);
}

MenuBase::~MenuBase() {
  delete _driver;
}

size_t MenuBase::addChoice(const string& choice) {
  size_t ret = _choices.size();
  _choices.push_back(choice);
  _driver->redraw(_choices);
  return ret;
}

size_t MenuBase::removeChoice(const string& choice) {
  size_t index;
  for(index = 0; index < _choices.size(); index++) {
    if(choice == _choices[index]) {
      _choices.erase(_choices.begin() + index);
      break;
    }
  }
  if(index != _choices.size()) {
    _driver->redraw(_choices);
  }
  return index;
}

void MenuBase::removeChoice(size_t index) {
  _choices.erase(_choices.begin() + index);
  _driver->redraw(_choices);
}

void MenuBase::clearChoices() {
  _choices.clear();
  _driver->redraw(_choices);
}

size_t MenuBase::listen() {
  int c;
  while((c = _driver->getChar()) != KEY_F(1)) {
    switch(c) {
      case KEY_DOWN:
        _driver->nextItem();
        break;
      case KEY_UP:
        _driver->previousItem();
        break;
      case KEY_NPAGE:
        _driver->previousPage();
        break;
      case KEY_PPAGE:
        _driver->nextPage();
        break;
      case KEY_LLDBENTER:
      case KEY_REALENTER:
        return _driver->makeSelection();
        break;
      default: {
        size_t choice;
        if(_driver->makeHotkeySelection(c, choice)) {
          Info("Selecting item " << choice << " using hotkey " << c);
          return choice;
        } else {
          Info("Character " << c << " not recognized as a valid hotkey");
        }
        break;
      }
    }
  }

  return _driver->numChoices();
}

void MenuBase::refresh() {
  _driver->refresh(_choices);
}

// ============= STATIC MENU ===============
StaticMenu::StaticMenu(const string& title, Window* window): MenuBase(title, window) {
  refresh();
}

bool StaticMenu::getChoice(string& choice) {
  size_t index = listen();
  bool valid = (index < _choices.size());
  if(valid) {
    choice = _choices[index];
  }
  return valid;
}

bool StaticMenu::getChoiceIndex(size_t& index) {
  index = listen();
  return (index < _choices.size());
}

// ============= DYNAMIC MENU ===============
DynamicMenu::DynamicMenu(const string& title, Window* window): MenuBase(title, window) {
}

size_t DynamicMenu::addChoice(const string& choice) {
  return MenuBase::addChoice(choice);
}

size_t DynamicMenu::addChoice(const string& choice, function<void()> func) {
  size_t index = MenuBase::addChoice(choice);
  _actions[index] = func;
  return index;
}

size_t DynamicMenu::removeChoice(const string& choice) {
  size_t index = MenuBase::removeChoice(choice);
  _actions.erase(index);
  return index;
}

void DynamicMenu::removeChoice(size_t index) {
  MenuBase::removeChoice(index);
  _actions.erase(index);
}

void DynamicMenu::clearChoices() {
  MenuBase::clearChoices();
  _actions.clear();
}

void DynamicMenu::setDefaultAction(function<void(string)> func) {
  _defaultAction = func;
}

bool DynamicMenu::act() {
  size_t index = listen();
  if(index == _choices.size()) {
    return false;
  }

  auto proc = _actions.find(index);
  if(proc != _actions.end()) {
    proc->second();
    return true;
  } else if(_defaultAction) {
    _defaultAction(_choices[index]);
    return true;
  } else {
    Error(L"No behavior defined for choice " << _choices[index]);
    return false;
  }
}
