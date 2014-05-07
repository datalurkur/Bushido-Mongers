#ifndef EVENTQUEUE_H
#define EVENTQUEUE_H

#include "io/gameevent.h"

#include <list>
#include <memory>

using namespace std;

typedef shared_ptr<GameEvent> SharedGameEvent;

// The purpose of the event list is to maintain control of game event memory
// Since it's necessary to pass around game event pointers, rather than references
//  (so they can be cast correctly), it makes more sense to allow a structure to control
//  teardown of the events rather than relying on programmer diligence
class EventQueue {
public:
  EventQueue();
  ~EventQueue();

  void pushEvent(GameEvent* event);
  void pushEvent(SharedGameEvent event);
  void appendEvents(EventQueue&& other);

  SharedGameEvent popEvent();

  list<SharedGameEvent>::const_iterator begin() const;
  list<SharedGameEvent>::const_iterator end() const;

  void clear();
  bool empty();

protected:
  list<SharedGameEvent> getMovableEvents();

private:
  list<SharedGameEvent> _events;
};

#endif
