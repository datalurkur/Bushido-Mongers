#ifndef CLIENT_TILE_H
#define CLIENT_TILE_H

#include "world/tilebase.h"

class ClientTile: public TileBase {
public:
  ClientTile(TileType type, set<BObjectID>&& contents);
  virtual ~ClientTile();

  Area* getArea() const;
  const IVec2& getCoordinates() const;

private:
  IVec2 _fakeCoordinates;
};

#endif
