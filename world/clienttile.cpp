#include "world/clienttile.h"

ClientTile::ClientTile(TileType type, set<BObjectID>&& contents): TileBase(type) {
  _contents = move(contents);
}
