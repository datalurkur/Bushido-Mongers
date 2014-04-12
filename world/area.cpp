#include "util/log.h"
#include "world/area.h"

Area::Area(const string& name, const IVec2& pos, const IVec2& size):
  AreaBase(name, pos, size) {}

Tile* Area::getRandomEmptyTile() {
  const int maxAttempts = 100;
  Tile* ret = 0;
  for(int c = 0; c < maxAttempts; c++) {
    int x = rand() % _size.x,
        y = rand() % _size.y;

    ret = (Tile*)getTile(IVec2(x, y));
    if(!ret) {
      Error("Found null tile at " << IVec2(x, y));
    }

    if(ret && ret->getType() != TileType::Ground) { return ret; }
  }

  Error("Failed to find random empty tile");
  return 0;
}

void Area::setTile(const IVec2& pos, TileBase* tile) {
  int index = (pos.x * _size.y) + pos.y;
  if(_tiles[index]) {
    Warn("Tile already exists");
    delete _tiles[index];
  }
  _tiles[index] = tile;
}

