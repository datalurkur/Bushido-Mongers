#ifndef CHOICE_H
#define CHOICE_H

#include <vector>
#include <list>
#include <string>

using namespace std;

class Choice {
public:
  Choice();
  Choice(const string& prompt);

  Choice(const vector<string>& choices);
  Choice(const list<string>& choices);

  void addChoice(const string& choice);

  bool getSelection(unsigned int &index, unsigned int retries = 3) const;
  bool getChoice(string& choice, unsigned int retries = 3) const;

private:
  void printChoices() const;

private:
  string _prompt;
  vector<string> _choices;
};

#endif
