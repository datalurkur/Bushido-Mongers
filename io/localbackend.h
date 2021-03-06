#ifndef LOCAL_BACKEND_H
#define LOCAL_BACKEND_H

#include "io/clientbase.h"
#include "world/clientworld.h"
#include "curseme/curselog.h"
#include "curseme/renderer.h"
#include "curseme/window.h"
#include "resource/raw.h"
#include "resource/visualization.h"
#include "ui/menu.h"

#include <thread>
#include <mutex>
#include <condition_variable>
#include <atomic>

using namespace std;

class RenderSource;

struct BObjectStub {
  string prototype;
};

class LocalBackEnd: virtual public ClientBase {
public:
  LocalBackEnd();
  ~LocalBackEnd();

  void enableCursor(bool enabled);
  void moveCursor(const IVec2& dir);

  bool sendToClient(EventQueue* queue);
  bool sendToClient(GameEvent* event);

private:
  void consumeEvents();
  void consumeSingleEvent(GameEvent* event);

  void unpackRaws(RawDataEvent* event);
  void changeArea();
  void updateMap(TileDataEvent* event);
  void updateObject(ObjectDataEvent* event);
  void moveObject(ThingMovedEvent* event);

  void updateTileRepresentation(const IVec2& coords, ClientArea* currentArea);

  void updateInfoPanel();

private:
  // Event queueing and consumption
  thread _eventConsumer;
  atomic<bool> _consumerShouldDie;
  mutex _eventLock;
  bool _eventsReady;
  condition_variable _eventsReadyCondition;
  EventQueue _events;

  // Local representation of the world
  ClientWorld _world;
  Raw _raw;
  RenderSource* _mapSource;
  BObjectID _characterID;
  map<BObjectID, BObjectStub> _objects;
  IVec2 _lastPlayerLocation;

  // UI
  Window* _logWindow;
  CursesLogWindow* _logPanel;
  Window* _mainWindow;
  Window* _infoWindow;
  Window* _mapWindow;
  RenderTarget* _mapPanel;
  DynamicMenu* _objectMenu;

  // Config
  VisualizationMap _objectRepresentation;

  // Cursor
  bool _cursorEnabled;
  IVec2 _cursorLocation;
};

#endif
