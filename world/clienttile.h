#ifndef CLIENT_TILE_H
#define CLIENT_TILE_H

#include "world/tilebase.h"

class ClientTile: public TileBase {
public:
  ClientTile(TileType type, set<BObjectID>&& contents);
};

#endif
