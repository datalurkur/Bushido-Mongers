#include "world/tilebase.h"
#include "util/structure.h"

TileBase::TileBase(TileType type): _type(type) {}

TileBase::~TileBase() {}

void TileBase::setType(TileType type) { _type = type; }

TileType TileBase::getType() const { return _type; }

TileDatum::TileDatum() {}
TileDatum::TileDatum(TileBase* tile): type(tile->getType()), contents(tile->getContents()) {}

ostream& operator<<(ostream& stream, TileDatum& data) {
  stream << data.type << data.contents;
  return stream;
}

istream& operator>>(istream& stream, TileDatum& data) {
  char temp;
  stream >> temp;
  data.type = static_cast<TileType>(temp);
  stream >> data.contents;
  return stream;
}
