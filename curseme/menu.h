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
#include "curseme/uistack.h"

using namespace std;

/* TODO
  * attach procs to selections.
  * don't just blithely assume that ncurses is otherwise enabled.
  * select key for actions.
  * fix choice/description mismatch? or don't use descriptions at all for now. - use pairs.
  * remember the placement from the last run, fer christ's sake.
*/

class Menu : public UIE {
public:
  Menu();
  Menu(const string& title);
  Menu(const list<string>& choices);
  Menu(const vector<string>& choices);

  void setTitle(const string& title);

  void addChoice(const string& choice);
  void addChoice(const string& choice, const string& description);

  void addChoice(const string& choice, function<void()> func);
  void addChoice(const string& choice, const string& description, function<void()> func);
  void setDefaultAction(function<void(string)> func);
  bool actOnChoice(const string& choice);

  unsigned int listen();
  bool getSelection(unsigned int& index);
  bool getChoice(string& choice);

  void setup();
  void teardown();

  void refresh_window();

  ~Menu();

private:
  // ncurses bookkeeping
  ITEM **_items;
  MENU  *_menu;
  TitleBox* _tb; // hangs onto the windows.

  unsigned int _size;

  string _title;
  vector<string> _choices;
  vector<string> _descriptions;

  unordered_map<string, function<void()> > _functions;
  function<void(string)> _def_fun;
};

#endif