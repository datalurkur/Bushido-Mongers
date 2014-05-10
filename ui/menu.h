#ifndef MENU_H
#define MENU_H

#include <functional>
#include <vector>
#include <map>
#include <string>
#include <sstream>

#include <menu.h>

#include "util/stringhelper.h"
#include "ui/titlebox.h"

using namespace std;

/* TODO
  * external setting of trigger keys.
*/

class MenuBase {
public:
  MenuBase(const string& title);

  virtual size_t addChoice(const string& choice);
  virtual size_t removeChoice(const string& choice);
  virtual void removeChoice(size_t index);
  virtual void clearChoices();

protected:
  size_t listen();

protected:
  string _title;
  vector<string> _choices;
};

class StaticMenu : public MenuBase {
public:
  StaticMenu(const string& title);

  template <typename T>
  StaticMenu(const string& title, const T& choices);

  bool getChoice(string& choice);
  bool getChoiceIndex(size_t& index);
};

template <typename T>
StaticMenu::StaticMenu(const string& title, const T& choices): MenuBase(title) {
  copy(choices.begin(), choices.end(), back_inserter(_choices));
}

class DynamicMenu : public MenuBase {
public:
  DynamicMenu(const string& title);

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
