#ifndef MENU_H
#define MENU_H

#include <functional>
#include <vector>
#include <string>
#include <sstream>
#include <list>

#include <menu.h>

#include "curseme/curseme.h"
#include "curseme/window.h"

using namespace std;

/* TODO
	* attach procs to selections.
	* don't just blithely assume that ncurses is otherwise enabled.
	* select key for actions.
*/

class Menu {
public:
  Menu();
  Menu(const string& title);
  Menu(const list<string>& choices);

  void setTitle(const string& title);
  void addChoice(const string& choice);
  void addChoice(const string& choice, const string& description);
  //void addChoice(string& choice, string& description, function<int> func);

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
  bool _deployed;

  string _title;
  vector<string> _choices;
  vector<string> _descriptions;
};

#endif