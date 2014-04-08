#include "io/eventqueue.h"

EventQueue::EventQueue() {
}

EventQueue::~EventQueue() {
  for(auto event : _events) {
    delete event;
  }
  _events.clear();
}

void EventQueue::pushEvent(GameEvent* event) {
  _events.push_back(event);
}

list<GameEvent*>::const_iterator EventQueue::begin() const {
  return _events.begin();
}

list<GameEvent*>::const_iterator EventQueue::end() const {
  return _events.end();
}
