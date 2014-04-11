#include "util/log.h"
#include "world/areabase.h"

AreaBase::AreaBase(const string& name, const IVec2& pos, const IVec2& size):
  _size(size), _name(name), _pos(pos) {
  _tiles.resize(_size.x * _size.y, 0);
}

AreaBase::~AreaBase() {
  for(auto tile : _tiles) {
    delete tile;
  }
  _tiles.clear();
}

const string& AreaBase::getName() const { return _name; }
const IVec2& AreaBase::getPos() const { return _pos; }
const IVec2& AreaBase::getSize() const { return _size; }

void AreaBase::addConnection(const string& other) {
  _connections.insert(other);
}

const set<string>& AreaBase::getConnections() const {
  return _connections;
}

TileBase* AreaBase::getTile(const IVec2& pos) { return _tiles[(pos.x * _size.y) + pos.y]; }
