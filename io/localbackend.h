#ifndef LOCAL_BACKEND_H
#define LOCAL_BACKEND_H

#include "io/clientbase.h"
#include "world/clientworld.h"
#include "curseme/curselog.h"
#include "curseme/renderer.h"

class RenderSource;

class LocalBackEnd: virtual public ClientBase {
public:
  LocalBackEnd();
  ~LocalBackEnd();

  void sendToClient(GameEvent* event);

private:
  void changeArea();
  void updateMap(TileDataEvent* event);

  char getTileRepresentation(TileType type);

private:
  ClientWorld* _world;
  RenderSource* _mapSource;

  WINDOW* _logWindow;
  CursesLogWindow* _logPanel;
  WINDOW* _mapWindow;
  RenderTarget* _mapPanel;
};

#endif
