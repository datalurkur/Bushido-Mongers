#include "world/clienttile.h"

ClientTile::ClientTile(TileType type, set<BObjectID>&& contents): TileBase(type), _fakeCoordinates(0,0) {
  _contents = move(contents);
}

ClientTile::~ClientTile() {
  // On the client-side, this is a no-op
  // Object locations come from the server and don't need to be maintained locally
}

Area* ClientTile::getArea() const {
  ASSERT(0, "getArea not implemented client-side"); // Not implemented for client-side
  return 0;
}

const IVec2& ClientTile::getCoordinates() const {
  ASSERT(0, "getCoordinates not implemented client-side"); // Not implemented for client-side
  return _fakeCoordinates;
}
