#include "curseme/uistack.h"
#include "util/log.h"

list<UIE*> UIStack::_stack = list<UIE*>();

UIE::UIE(): _deployed(false) {}

UIE::~UIE() {}

bool UIE::deployed() {
  return _deployed;
}

void UIStack::push(UIE* uie) {
  Debug("UIStack push " << uie << " (" << (_stack.size()+1) << ")");
  if(!_stack.empty()) {
    _stack.back()->teardown();
  }
  uie->setup();
  _stack.push_back(uie);
}

void UIStack::pop() {
  if(!_stack.empty()) {
    Debug("UIStack pop " << _stack.back() << " (" << (_stack.size()-1) << ")");
    UIE* uie = _stack.back();
    _stack.pop_back();

    uie->teardown();
  } else {
    Debug("UIStack pop on empty stack!");
  }
  if(!_stack.empty()) {
    _stack.back()->setup();
  }
}