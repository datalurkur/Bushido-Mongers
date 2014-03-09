#include "world/tile.h"
#include "util/log.h"

Tile::Tile(): _type(Type::Wall) {
}

Tile::~Tile() {}

void Tile::setType(Tile::Type type) { _type = type; }

Tile::Type Tile::getType() const { return _type; }
