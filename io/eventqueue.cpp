#include "io/eventqueue.h"

EventQueue::EventQueue() {
}

EventQueue::~EventQueue() {
  clear();
}

void EventQueue::pushEvent(GameEvent* event) {
  _events.push_back(SharedGameEvent(event));
}

void EventQueue::pushEvent(SharedGameEvent event) {
  _events.push_back(event);
}

SharedGameEvent EventQueue::popEvent() {
  ASSERT(!empty(), "Event queue is empty!");
  SharedGameEvent event = _events.front();
  _events.pop_front();
  return event;
}

void EventQueue::appendEvents(EventQueue&& other) {
  _events.splice(_events.end(), other.getMovableEvents());
}

list<SharedGameEvent>::const_iterator EventQueue::begin() const {
  return _events.begin();
}

list<SharedGameEvent>::const_iterator EventQueue::end() const {
  return _events.end();
}

void EventQueue::clear() {
  _events.clear();
}

bool EventQueue::empty() {
  return _events.empty();
}

list<SharedGameEvent>&& EventQueue::getMovableEvents() { return move(_events); }
