#include "io/eventmeta.h"

ostream& operator<<(ostream& stream, const GameEventType& type) {
  stream << (GameEventTypeSize)type;
  return stream;
}

istream& operator>>(istream& stream, GameEventType& type) {
  GameEventTypeSize temp;
  stream >> temp;
  type = static_cast<GameEventType>(temp);
  return stream;
}

GameEvent::GameEvent(GameEventType t): type(t) {}

void GameEvent::Pack(GameEvent* event, ostringstream& str) {
  str << event->type;
  event->pack(str);
}
