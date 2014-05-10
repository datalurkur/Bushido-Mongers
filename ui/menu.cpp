#include "ui/menu.h"
#include "curseme/menudriver.h"
#include "util/log.h"

#include <iostream>
#include <algorithm>
#include <string>

// whut.
#define KEY_LLDBENTER 10
#define KEY_REALENTER 13
#define CTRLD   4

// ============= MENU BASE ===============
MenuBase::MenuBase(const string& title): _title(title) {}

size_t MenuBase::addChoice(const string& choice) {
  size_t ret = _choices.size();
  _choices.push_back(choice);
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
  return index;
}

void MenuBase::removeChoice(size_t index) {
  _choices.erase(_choices.begin() + index);
}

void MenuBase::clearChoices() {
  _choices.clear();
}

size_t MenuBase::listen() {
  MenuDriver driver(_title, _choices, " * ");

  int c;
  while((c = driver.getChar()) != KEY_F(1)) {
    switch(c) {
      case KEY_DOWN:
        driver.nextItem();
        break;
      case KEY_UP:
        driver.previousItem();
        break;
      case KEY_NPAGE:
        driver.previousPage();
        break;
      case KEY_PPAGE:
        driver.nextPage();
        break;
      case KEY_LLDBENTER:
      case KEY_REALENTER:
        return driver.makeSelection();
        break;
      default:
        Info("Character pressed: " << c << " (char: " << ((char)c) << ")");
        break;
    }
  }

  return driver.getNumItems();
}

// ============= STATIC MENU ===============
StaticMenu::StaticMenu(const string& title): MenuBase(title) {}

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
DynamicMenu::DynamicMenu(const string& title): MenuBase(title) {
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
