#include "io/eventqueue.h"
#include "util/assertion.h"

EventQueue::EventQueue() {
  //Debug("  Event queue " << this << " being constructed");
}

EventQueue::~EventQueue() {
  clear();
}

void EventQueue::pushEvent(GameEvent* event) {
  //Debug("  Event " << event << " added to queue " << this);
  _events.push_back(event);
}

void EventQueue::appendQueue(EventQueue* queue) {
  //Debug("  Cloning event queue " << queue << " into " << this);
  for(auto e : *queue) {
    GameEvent* newEvent = e->clone();
    //Debug("Replacing event " << e << " with clone " << newEvent);
    _events.push_back(newEvent);
  }
}

list<GameEvent*>::const_iterator EventQueue::begin() const {
  return _events.begin();
}

list<GameEvent*>::const_iterator EventQueue::end() const {
  return _events.end();
}

void EventQueue::clear() {
  //Debug("  Event queue " << this << " being cleared");
  for(auto e : _events) {
    delete e;
  }
  _events.clear();
}

bool EventQueue::empty() {
  return _events.empty();
}
