#ifndef GAME_SERVER_H
#define GAME_SERVER_H

#include "io/serverbase.h"

class GameServer: public ServerBase {
public:
  GameServer(const string& rawSet);
  ~GameServer();
};

#endif
