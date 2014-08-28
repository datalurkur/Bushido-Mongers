#ifndef MENU_H
#define MENU_H

#include <functional>
#include <vector>
#include <map>
#include <string>
#include <sstream>

#include "curseme/hotkeymenudriver.h"
#include "util/stringhelper.h"
#include "ui/titlebox.h"

using namespace std;

/* TODO
  * external setting of trigger keys.
*/

class MenuBase {
public:
  MenuBase(const string& title, Window* window);
  virtual ~MenuBase();

  virtual size_t addChoice(const string& choice);
  virtual size_t removeChoice(const string& choice);
  virtual void removeChoice(size_t index);
  virtual void clearChoices();

protected:
  size_t listen();

private:
  void refreshDriver();

protected:
  string _title;
  vector<string> _choices;

  Window* _window;
  HotkeyMenuDriver* _driver;
};

class StaticMenu : public MenuBase {
public:
  StaticMenu(const string& title, Window* window = 0);

  template <typename T>
  StaticMenu(const string& title, const T& choices, Window* window = 0);

  bool getChoice(string& choice);
  bool getChoiceIndex(size_t& index);
};

template <typename T>
StaticMenu::StaticMenu(const string& title, const T& choices, Window* window): MenuBase(title, window) {
  copy(choices.begin(), choices.end(), back_inserter(_choices));
}

class DynamicMenu : public MenuBase {
public:
  DynamicMenu(const string& title, Window* window = 0);

  size_t addChoice(const string& choice);
  size_t addChoice(const string& choice, function<void()> func);
  size_t removeChoice(const string& choice);
  void removeChoice(size_t index);
  void clearChoices();

  void setDefaultAction(function<void(string)> func);

  bool act();

private:
  map<size_t, function<void()> > _actions;
  function<void(string)> _defaultAction;
};

#endif
