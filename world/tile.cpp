#include "world/tile.h"
#include "util/log.h"

Tile::Tile(): _type(Type::Wall) {
}

Tile::Tile(Tile::Type type): _type(type) {
}

Tile::~Tile() {}

void Tile::setType(Tile::Type type) { _type = type; }

Tile::Type Tile::getType() const { return _type; }

void Tile::setArea(Area* area) { _area = area; }

Area* Tile::getArea() const { return _area; }

const IVec2* Tile::getCoordinates() const { return &_pos; }

void Tile::setCoordinates(const IVec2& pos) { _pos = pos; }
