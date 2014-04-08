#include "util/log.h"
#include "world/area.h"

Area::Area(const string& name, const IVec2& pos, const IVec2& size):
  _size(size), _name(name), _pos(pos) {
  _tiles.resize(_size.x * _size.y, 0);
}

Area::~Area() {
  _tiles.clear();
}

const string& Area::getName() const { return _name; }
const IVec2& Area::getPos() const { return _pos; }
const IVec2& Area::getSize() const { return _size; }

void Area::addConnection(Area *o) {
  _connections.insert(o);
}

const set<Area*>& Area::getConnections() const {
  return _connections;
}

Tile* Area::getTile(int x, int y) { return _tiles[(x * _size.y) + y]; }
Tile* Area::getTile(const IVec2& pos) { return _tiles[(pos.x * _size.y) + pos.y]; }

Tile* Area::getRandomEmptyTile() {
  Tile* ret = 0;
  while(!ret) {
    int x = rand() % _size.x,
        y = rand() % _size.y;
    ret = getTile(x,  y);
    if(ret->getType() != Tile::Type::Ground) { ret = 0; }
  }
  return ret;
}

void Area::setTile(int x, int y, Tile* tile) {
  int index = (x * _size.y) + y;
  if(_tiles[index]) {
    Warn("Tile already exists");
    delete _tiles[index];
  }
  _tiles[index] = tile;
  tile->setCoordinates(IVec2(x, y));
}

void Area::setTile(const IVec2& pos, Tile* tile) {
  setTile(pos.x, pos.y, tile);
}

ClientArea::ClientArea(const string& name, const IVec2& pos, const IVec2& size):
  Area(name, pos, size) {
  _shrouded.resize(_size.x * _size.y, true);
}

ClientArea::~ClientArea() {
  _shrouded.clear();
}

void ClientArea::shroudTile(const IVec2& pos) { _shrouded[(pos.x * _size.y) + pos.y] = true; }
void ClientArea::revealTile(const IVec2& pos) { _shrouded[(pos.x * _size.y) + pos.y] = false; }
bool ClientArea::isTileShrouded(const IVec2& pos) { return _shrouded[(pos.x * _size.y) + pos.y]; }
