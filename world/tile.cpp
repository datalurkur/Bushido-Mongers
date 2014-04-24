#include "world/tile.h"
#include "util/log.h"
#include "util/assertion.h"

Tile::Tile(Area* area, const IVec2& pos, TileType type): TileBase(type), _pos(pos), _area(area) {}

Tile::~Tile() {
  // Objects should be torn down before the world, and should remove themselves from the world / area / tile appropriately
  // By the time that happens, the contents should be empty
  ASSERT(_contents.size() == 0, "Tile contents not correctly torn down");
}

Area* Tile::getArea() const { return _area; }

const IVec2& Tile::getCoordinates() const { return _pos; }

