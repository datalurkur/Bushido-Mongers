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

typedef pair<string, string> StringPair;

// A hash method for StringPair, so we can use it as a key-type for an unordered_map.
namespace std
{
template<>
struct hash<StringPair> {
    size_t operator()(const StringPair &sp) const {
        return hash<string>()(sp.first) ^ hash<string>()(sp.second);
    }
};
}
typedef unordered_map<StringPair, function<void()> > StringPairFunctionMap;

class Menu {
public:
  Menu();
  Menu(const string& title);

  // The function fills out the choices, and is used dynamically during menu setup.
  Menu(const string& title, function<void(Menu*)> redraw_func);

  Menu(const list<string>& choices);
  Menu(const vector<string>& choices);

  void setTitle(const string& title);

  void addChoice(const string& choice);
  void addChoice(const StringPair& choice);

  void addChoice(const string& choice, function<void()> func);
  void addChoice(const StringPair& choice, function<void()> func);

  void removeChoice(const StringPair& choice);

  void setDefaultAction(function<void(StringPair)> func);
private:
  bool actOnChoice(const StringPair& choice);
public:
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

  vector<StringPair> _choices;

  StringPairFunctionMap _functions;
  function<void(StringPair)> _def_fun;

  bool _end_on_selection;

  function<void(Menu*)> _redraw_func;

  bool _deployed;

  bool _empty_menu;
};

#endif