#include "world/tile.h"
#include "util/log.h"

Tile::Tile(Area* area, const IVec2& pos, TileType type): TileBase(type), _pos(pos), _area(area) {}

Area* Tile::getArea() const { return _area; }

const IVec2& Tile::getCoordinates() const { return _pos; }

