#include "io/eventmeta.h"
#include "util/stringhelper.h"

ostream& operator<<(ostream& stream, const GameEventType& type) {
  stream << (GameEventTypeSize)type;
  return stream;
}

GameEvent::GameEvent(GameEventType t): type(t) {
  //Info("    Game event of type " << type << " being created (" << this << ")");
}

GameEvent::~GameEvent() {
  //Info("    Game event of type " << type << " begin torn down (" << this << ")");
}

void GameEvent::Pack(GameEvent* event, ostringstream& str) {
  genericBufferToStream(str, event->type);
  event->pack(str);
}
