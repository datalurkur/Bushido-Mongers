#include "world/tilebase.h"
#include "util/structure.h"
#include "util/streambuffering.h"

TileBase::TileBase(TileType type): _type(type) {}

TileBase::~TileBase() {}

void TileBase::setType(TileType type) { _type = type; }

TileType TileBase::getType() const { return _type; }

TileDatum::TileDatum() {}
TileDatum::TileDatum(TileBase* tile): type(tile->getType()), contents(tile->getContents()) {}

void bufferToStream(ostringstream& stream, const TileDatum& data) {
  genericBufferToStream(stream, data.type);
  bufferToStream(stream, data.contents);
}

void bufferFromStream(istringstream& stream, TileDatum& data) {
  genericBufferFromStream(stream, data.type);
  bufferFromStream(stream, data.contents);
}
