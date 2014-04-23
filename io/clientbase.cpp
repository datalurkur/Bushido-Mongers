#include "io/clientbase.h"
#include "io/gameevent.h"
#include "world/clientworld.h"

ClientBase::ClientBase(): _done(false), _eventsReady(false) {
  _world = new ClientWorld();
  _eventConsumer = thread(&ClientBase::consumeEvents, this);
}

ClientBase::~ClientBase() {
  if(_eventConsumer.joinable()) {
    _eventsReadyCV.notify_all();
    _done = true;
    _eventConsumer.join();
  }
  delete _world;
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

void ClientBase::processEvent(GameEvent* event) {
  switch(event->type) {
    case AreaData:
    case TileData: {
      EventQueue results;
      _world->processWorldEvent(event, results);
      for(auto result : results) {
        sendToServer(result.get());
      }
      break;
    }
    case CharacterReady:
      Debug("Character is ready");
      break;
    case CharacterNotReady:
      Debug("Character not ready - " << ((CharacterNotReadyEvent*)event)->reason);
      break;
    case CharacterMoved:
      Debug("Character moved");
      break;
    case MoveFailed:
      Debug("Failed to move - " << ((MoveFailedEvent*)event)->reason);
      break;
    default:
      Warn("Unhandled game event type " << event->type);
      break;
  }
}

//void ClientBase::queueToClient(GameEvent* event) {
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
