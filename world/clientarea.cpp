#include "world/clientarea.h"

ClientArea::ClientArea(const string& name, const IVec2& pos, const IVec2& size):
  AreaBase(name, pos, size) {
  _shrouded.resize(_size.x * _size.y, true);
}

ClientArea::~ClientArea() {
  _shrouded.clear();
}

void ClientArea::shroudTile(const IVec2& pos) { _shrouded[(pos.x * _size.y) + pos.y] = true; }
void ClientArea::revealTile(const IVec2& pos) { _shrouded[(pos.x * _size.y) + pos.y] = false; }
bool ClientArea::isTileShrouded(const IVec2& pos) { return _shrouded[(pos.x * _size.y) + pos.y]; }

void ClientArea::setTile(const IVec2& pos, TileBase* tile) {
  int index = (pos.x * _size.y) + pos.y;
  if(_tiles[index]) {
    delete _tiles[index];
  }
  _tiles[index] = tile;
}
