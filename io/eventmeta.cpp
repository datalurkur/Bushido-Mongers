#include "io/eventmeta.h"
#include "util/stringhelper.h"

ostream& operator<<(ostream& stream, const GameEventType& type) {
  stream << (GameEventTypeSize)type;
  return stream;
}

GameEvent::GameEvent(GameEventType t): type(t) {}

GameEvent::~GameEvent() {}

void GameEvent::Pack(GameEvent* event, ostringstream& str) {
  genericBufferToStream(str, event->type);
  event->pack(str);
}
