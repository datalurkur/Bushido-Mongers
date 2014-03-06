#include "world/area.h"

Area::Area(const string& name, int xPos, int yPos, int xSize, int ySize): _name(name), _xPos(xPos), _yPos(yPos), _xSize(xSize), _ySize(ySize) {}
Area::~Area() {}

const string& Area::getName() const { return _name; }
int Area::getXPos() const { return _xPos; }
int Area::getYPos() const { return _yPos; }

void Area::addConnection(Area *o) {
  _connections.insert(o);
}
