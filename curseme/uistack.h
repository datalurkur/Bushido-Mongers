#ifndef UISTACK_H
#define UISTACK_H

#include <list>

using namespace std;

class UIE {
public:
  UIE();
  virtual ~UIE() = 0;

  virtual void setup() = 0;
  virtual void teardown() = 0;

  bool deployed();
protected:
  bool _deployed;
};

class UIStack {
public:
  static void push(UIE* uie);
  static void pop();
private:
  static list<UIE*> _stack;
};

#endif