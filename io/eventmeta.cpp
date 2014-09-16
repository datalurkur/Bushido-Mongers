#include "io/eventmeta.h"
#include "util/stringhelper.h"
#include "util/log.h"

ostream& operator<<(ostream& stream, const GameEventType& type) {
  stream << (GameEventTypeSize)type;
  return stream;
}

GameEvent::GameEvent(GameEventType t): type(t) {
  //Info("    Game event of type " << type << " being created (" << this << ")");
  if(GameEvent::TrackAllocations) { GameEvent::Allocations++; }
}

GameEvent::~GameEvent() {
  //Info("    Game event of type " << type << " begin torn down (" << this << ")");
  if(GameEvent::TrackAllocations) { GameEvent::Allocations--; }
}

void GameEvent::Pack(GameEvent* event, ostringstream& str) {
  genericBufferToStream(str, event->type);
  event->pack(str);
}

bool GameEvent::TrackAllocations = false;
long GameEvent::Allocations = 0;

void GameEvent::BeginTrackingAllocations() {
  GameEvent::TrackAllocations = true;
  GameEvent::Allocations = 0;
}

void GameEvent::FinishTrackingAllocations() {
  GameEvent::TrackAllocations = false;
  ASSERT(GameEvent::Allocations == 0, "More than 0 GameEvent objects were not properly torn down");
  Debug("GameEvent allocations are clean");
}
