#include "world/tile.h"
#include "util/log.h"

Tile::Tile(Area* area, const IVec2& pos, Tile::Type type): _area(area), _pos(pos), _type(type) {
}

Tile::~Tile() {
}

void Tile::setType(Tile::Type type) { _type = type; }

Tile::Type Tile::getType() const { return _type; }

Area* Tile::getArea() const { return _area; }

const IVec2& Tile::getCoordinates() const { return _pos; }
