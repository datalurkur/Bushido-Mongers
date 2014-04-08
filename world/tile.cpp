#include "world/tile.h"
#include "util/log.h"

Tile::Tile(Area* area): _area(area), _type(Type::Wall) {
}

Tile::Tile(Area* area, Tile::Type type): _area(area), _type(type) {
}

Tile::~Tile() {}

void Tile::setType(Tile::Type type) { _type = type; }

Tile::Type Tile::getType() const { return _type; }

Area* Tile::getArea() const { return _area; }

const IVec2* Tile::getCoordinates() const { return &_pos; }

void Tile::setCoordinates(const IVec2& pos) { _pos = pos; }
