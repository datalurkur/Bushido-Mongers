#include "interface/choice.h"
#include "util/log.h"

#include <iostream>

Choice::Choice(): _prompt("Make a selection") {}

Choice::Choice(const string& prompt): _prompt(prompt) {}
  
Choice::Choice(const vector<string>& choices): _prompt("Make a selection"), _choices(choices) {}

Choice::Choice(const list<string>& choices): _prompt("Make a selection") {
  for(list<string>::const_iterator itr = choices.begin(); itr != choices.end(); itr++) {
    _choices.push_back(*itr);
  }
}

void Choice::addChoice(const string& choice) {
  _choices.push_back(choice);
}

bool Choice::getSelection(int &choice, int retries) const {
  int c;
  for(int i = 0; i < retries; i++) {
    printChoices();
    cin >> c;
    Info("");
    if(c > 0 && c <= _choices.size()) {
      choice = c - 1;
      return true;
    } else if(c == _choices.size() + 1) {
      return false;
    } else {
      Info("Please enter a value between 1 and " << _choices.size() + 1);
    }
  }
  return false;
}

bool Choice::getChoice(string& choice, int retries) const {
  int index;
  if(getSelection(index, retries)) {
    choice = _choices[index];
    return true;
  } else {
    return false;
  }
}

void Choice::printChoices() const {
  int c;
  Info(_prompt);
  for(c = 0; c < _choices.size(); c++) {
    Info(c + 1 << ". " << _choices[c]);
  }
  Info(c + 1 << ". " << "Cancel");
}
