#ifndef EVENTMAP_H
#define EVENTMAP_H

#include "io/eventqueue.h"

#include <map>

using namespace std;

template <typename T>
class EventMap {
public:
  EventMap();
  ~EventMap();

  void pushEvent(T id, GameEvent* event);

  EventQueue* getEventQueue(T id);

  typename map<T, EventQueue*>::const_iterator begin() const;
  typename map<T, EventQueue*>::const_iterator end() const;

private:
  map<T, EventQueue*> _mappedEvents;
};

template <typename T>
EventMap<T>::EventMap() {
  //Debug("Constructing event map " << this);
}

template <typename T>
EventMap<T>::~EventMap() {
  //Debug("Tearing down event map " << this);
  for(auto i : _mappedEvents) {
    delete i.second;
  }
  _mappedEvents.clear();
}

template <typename T>
void EventMap<T>::pushEvent(T id, GameEvent* event) {
  EventQueue* q = getEventQueue(id);
  q->pushEvent(event);
}

template <typename T>
EventQueue* EventMap<T>::getEventQueue(T id) {
  auto mappedPair = _mappedEvents.find(id);
  if(mappedPair == _mappedEvents.end()) {
    auto result = _mappedEvents.insert(make_pair(id, new EventQueue()));
    return result.first->second;
  }
  return mappedPair->second;
}

template <typename T>
typename map<T, EventQueue*>::const_iterator EventMap<T>::begin() const {
  return _mappedEvents.begin();
}

template <typename T>
typename map<T, EventQueue*>::const_iterator EventMap<T>::end() const {
  return _mappedEvents.end();
}

#endif
