#include "world/area.h"

Area::Area(int xSize, int ySize): _xSize(xSize), _ySize(ySize) {}
Area::~Area() {}

void Area::addConnection(Area *o) {
  _connections.insert(o);
}
