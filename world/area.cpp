#include "util/log.h"
#include "world/area.h"

Area::Area(const string& name, const Vec2& pos, const Vec2& size):
  _name(name), _pos(pos), _size(size) {
  _tiles.resize(_size.x * _size.y);
}

Area::~Area() {
  _tiles.clear();
}

const string& Area::getName() const { return _name; }
const Vec2& Area::getPos() const { return _pos; }
const Vec2& Area::getSize() const { return _size; }

void Area::addConnection(Area *o) {
  _connections.insert(o);
}

const set<Area*>& Area::getConnections() const {
  return _connections;
}

Tile& Area::getTile(int x, int y) { return _tiles[(x * _size.y) + y]; }
Tile& Area::getTile(const Vec2& pos) { return _tiles[(pos.x * _size.y) + pos.y]; }
