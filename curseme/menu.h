#ifndef MENU_H
#define MENU_H

#include <string>
#include <vector>
#include <sstream>

using namespace std;

class SizeMismatchException : public exception {
  virtual const char* what() const throw() { return "The number of choices must match the number of descriptions"; }
};

class Menu {
public:
  Menu(const vector<string>& choices);
  Menu(const vector<string>& choices, const vector<string>& descriptions);
  ~Menu();

  void prompt();

private:
  void setup();
  void teardown();

private:
  vector<string>* _choices;
  vector<string>* _descriptions;

  MENU* _menu;
  ITEM** _items;
};

#endif
