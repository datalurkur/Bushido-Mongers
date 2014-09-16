#ifndef CLIENT_WORLD_H
#define CLIENT_WORLD_H

#include "world/worldbase.h"

struct GameEvent;
class ClientArea;

class ClientWorld: public WorldBase {
public:
  ClientWorld();

  void processWorldEvent(GameEvent* event);

  ClientArea* getCurrentArea();

private:
  ClientArea* _currentArea;
};

#endif
