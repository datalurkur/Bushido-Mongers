#ifndef CLIENTBASE_H
#define CLIENTBASE_H

#include "game/bobject.h"
#include "util/vector.h"

#include <string>
using namespace std;

struct GameEvent;
class World;
class ClientArea;

class ClientBase {
public:
  ClientBase();
  virtual ~ClientBase();

  virtual bool connectSender() = 0;
  virtual void disconnectSender() = 0;
  virtual void sendToServer(GameEvent* event) = 0;
  virtual void sendToClient(GameEvent* event) = 0;

  void createCharacter(const string& name);
  void loadCharacter(BObjectID id);
  void unloadCharacter();
  void moveCharacter(const IVec2& dir);

protected:
  void processEvent(GameEvent* event);

protected:
  World* _world;
  ClientArea* _currentArea;
};

#endif
