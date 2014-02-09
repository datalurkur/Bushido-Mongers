#ifndef CHOICE_H
#define CHOICE_H

#include <vector>
#include <list>

using namespace std;

class Choice {
public:
  Choice();
  Choice(const vector<string>& choices);
  Choice(const list<string>& choices);

  void addChoice(const string& choice);

  bool getSelection(int &index, int retries = 3) const;
  bool getChoice(string& choice, int retries = 3) const;

private:
  void printChoices() const;

private:
  vector<string> _choices;
};

#endif
