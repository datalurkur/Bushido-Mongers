#ifndef EVENTQUEUE_H
#define EVENTQUEUE_H

#include "io/gameevent.h"

#include <list>
#include <memory>

using namespace std;

// The purpose of the event list is to maintain control of game event memory
// Since it's necessary to pass around game event pointers, rather than references
//  (so they can be cast correctly), it makes more sense to allow a structure to control
//  teardown of the events rather than relying on programmer diligence
class EventQueue {
public:
  EventQueue();
  ~EventQueue();

  void pushEvent(GameEvent* event);
  void appendQueue(EventQueue* queue);

  list<GameEvent*>::const_iterator begin() const;
  list<GameEvent*>::const_iterator end() const;

  void clear();
  bool empty();

private:
  list<GameEvent*> _events;
};

#endif
