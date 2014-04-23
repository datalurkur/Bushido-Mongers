#include "io/clientbase.h"
#include "io/gameevent.h"

ClientBase::ClientBase(): _done(false), _eventsReady(false) {
  _eventConsumer = thread(&ClientBase::consumeEvents, this);
}

ClientBase::~ClientBase() {
  if(_eventConsumer.joinable()) {
    _eventsReadyCV.notify_all();
    _done = true;
    _eventConsumer.join();
  }
}

void ClientBase::createCharacter(const string& name) {
  // TODO - pass config data into this
  CreateCharacterEvent event(name);
  sendToServer(&event);
}

void ClientBase::loadCharacter(BObjectID id) {
  LoadCharacterEvent event(id);
  sendToServer(&event);
}

void ClientBase::unloadCharacter() {
  UnloadCharacterEvent event;
  sendToServer(&event);
}

void ClientBase::moveCharacter(const IVec2& dir) {
  MoveCharacterEvent event(dir);
  sendToServer(&event);
}

void ClientBase::queueToClient(SharedGameEvent event) {
  unique_lock<mutex> lock(_queueLock);
  _clientEventQueue.pushEvent(event);
  _eventsReady = true;
  _eventsReadyCV.notify_all();
}

void ClientBase::queueToClient(EventQueue&& queue) {
  unique_lock<mutex> lock(_queueLock);
  _clientEventQueue.appendEvents(move(queue));
  _eventsReady = true;
  _eventsReadyCV.notify_all();
}

void ClientBase::consumeEvents() {
  while(!_done) {
    unique_lock<mutex> lock(_queueLock);
    while(!_eventsReady && !_done) _eventsReadyCV.wait(lock);

    if(_clientEventQueue.empty()) { continue; }
    SharedGameEvent event = _clientEventQueue.popEvent();
    if(_clientEventQueue.empty()) {
      _eventsReady = false;
    }
    lock.unlock();
    sendToClient(event.get());
  }
}
