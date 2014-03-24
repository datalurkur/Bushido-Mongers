#include "curseme/uistack.h"

list<UIE*> UIStack::_stack = list<UIE*>();

UIE::UIE(): _deployed(false) {}

UIE::~UIE() {}

void UIStack::push(UIE* uie) {
  if(!_stack.empty()) {
    _stack.back()->teardown();
  }
  uie->setup();
  _stack.push_back(uie);
}

void UIStack::pop() {
  if(!_stack.empty()) {
    UIE* uie = _stack.back();
    _stack.pop_back();

    uie->teardown();
  }
  if(!_stack.empty()) {
    _stack.back()->setup();
  }
}