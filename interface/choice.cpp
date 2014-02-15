#include "interface/choice.h"
#include "interface/console.h"
#include "util/log.h"

#include <iostream>
#include <string>

using namespace std;

Choice::Choice(): _prompt("Make a selection") {}

Choice::Choice(const string& prompt): _prompt(prompt) {}
  
Choice::Choice(const vector<string>& choices): _prompt("Make a selection"), _choices(choices) {}

Choice::Choice(const list<string>& choices): _prompt("Make a selection") {
  for(string choice : choices) { _choices.push_back(choice); }
}

void Choice::addChoice(const string& choice) {
  _choices.push_back(choice);
}

bool Choice::getSelection(unsigned int &choice, unsigned int retries) const {
  unsigned int c;
  for(unsigned int i = 0; i < retries; i++) {
    printChoices();
    if(!Console::GetNumericInput<unsigned int>(c) || c <= 0 || c >= _choices.size() + 1) {
      Info("Please enter a value between 1 and " << _choices.size() + 1);
    }
    if(c == _choices.size() + 1) {
      return false;
    } else {
      choice = c - 1;
      Info("");
      return true;
    }
  }
  return false;
}

bool Choice::getChoice(string& choice, unsigned int retries) const {
  unsigned int index;
  if(getSelection(index, retries)) {
    choice = _choices[index];
    return true;
  } else {
    return false;
  }
}

void Choice::printChoices() const {
  unsigned int c;
  Info(_prompt);
  for(c = 0; c < _choices.size(); c++) {
    Info(c + 1 << ". " << _choices[c]);
  }
  Info(c + 1 << ". " << "Cancel");
}
