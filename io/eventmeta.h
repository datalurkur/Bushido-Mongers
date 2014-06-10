#ifndef EVENT_META_H
#define EVENT_META_H

#include "game/bobject.h"
#include "world/tilebase.h"

#include "util/streambuffering.h"

#include <sstream>
#include <string>
using namespace std;

typedef unsigned short GameEventTypeSize;
enum GameEventType : GameEventTypeSize;

extern ostream& operator<<(ostream& stream, const GameEventType& type);

struct GameEvent {
  GameEventType type;

  GameEvent(GameEventType t);
  virtual ~GameEvent();

  virtual void unpack(istringstream& str) = 0;
  virtual void pack(ostringstream& str) = 0;

  static void Pack(GameEvent* event, ostringstream& str);
  static GameEvent* Unpack(istringstream& str);
};


#endif
