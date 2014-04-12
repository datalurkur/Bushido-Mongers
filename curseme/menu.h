#ifndef MENU_H
#define MENU_H

#include <functional>
#include <vector>
#include <string>
#include <sstream>
#include <list>
#include <unordered_map>

#include <menu.h>

#include "curseme/curseme.h"
#include "curseme/window.h"

using namespace std;

/* TODO
  * select key for actions.
  * switch choice/descriptions to pairs.
*/

class Menu : public UIE {
public:
  Menu();
  Menu(const string& title);

  // The function fills out the choices, and is used dynamically during menu setup.
  Menu(const string& title, function<void(Menu*)> redraw_func);

  Menu(const list<string>& choices);
  Menu(const vector<string>& choices);

  void setTitle(const string& title);

  void addChoice(const string& choice);
  void addChoice(const string& choice, const string& description);

  void addChoice(const string& choice, function<void()> func);
  void addChoice(const string& choice, const string& description, function<void()> func);

  void removeChoice(const string& choice);

  //void addChoices(const list<string>& choices, function<void()> func);

  void setDefaultAction(function<void(string)> func);
  bool actOnChoice(const string& choice);

  void setEndOnSelection(bool val);

  unsigned int listen();
  bool getSelection(unsigned int& index);
  bool getChoice(string& choice);

  void setup();
  void teardown();

  void refresh_window();
  void clear_choices();

  ~Menu();

private:
  // ncurses bookkeeping
  ITEM **_items;
  MENU  *_menu;
  TitleBox* _tb; // hangs onto the windows.

  unsigned int _index;
  unsigned int _size;

  string _title;
  vector<string> _choices;
  vector<string> _descriptions;

  unordered_map<string, function<void()> > _functions;
  function<void(string)> _def_fun;

  bool _end_on_selection;

  function<void(Menu*)> _redraw_func;
};

#endif