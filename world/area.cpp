#include "util/log.h"
#include "world/area.h"

Area::Area(const string& name, int xPos, int yPos, int xSize, int ySize):
  _name(name), _xPos(xPos), _yPos(yPos), _xSize(xSize), _ySize(ySize) {
  _tiles.resize(xSize * ySize);
}

Area::~Area() {
  _tiles.clear();
}

const string& Area::getName() const { return _name; }
int Area::getXPos() const { return _xPos; }
int Area::getYPos() const { return _yPos; }
int Area::getXSize() const { return _xSize; }
int Area::getYSize() const { return _ySize; }

void Area::addConnection(Area *o) {
  _connections.insert(o);
}

Tile& Area::getTile(int x, int y) { return _tiles[(x * _ySize) + y]; }
