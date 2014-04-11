#ifndef CLIENTBASE_H
#define CLIENTBASE_H

#include "io/eventqueue.h"
#include "game/bobject.h"
#include "util/vector.h"

#include <thread>
#include <string>
using namespace std;

struct GameEvent;
class ClientWorld;
class ClientArea;

class ClientBase {
public:
  ClientBase();
  virtual ~ClientBase();

  virtual bool connectSender() = 0;
  virtual void disconnectSender() = 0;
  virtual void sendToServer(GameEvent* event) = 0;

  //void queueToClient(GameEvent* event);
  void queueToClient(SharedGameEvent event);
  void queueToClient(EventQueue&& queue);

  void createCharacter(const string& name);
  void loadCharacter(BObjectID id);
  void unloadCharacter();
  void moveCharacter(const IVec2& dir);

protected:
  void processEvent(GameEvent* event);
  virtual void sendToClient(GameEvent* event) = 0;

private:
  void consumeEvents();

protected:
  ClientWorld* _world;

  atomic<bool> _done;

  bool _eventsReady;
  mutex _queueLock;
  condition_variable _eventsReadyCV;
  thread _eventConsumer;
  EventQueue _clientEventQueue;
};

#endif
