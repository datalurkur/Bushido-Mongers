#ifndef TILE_H
#define TILE_H

#include "world/tilebase.h"

class Tile: public TileBase {
public:
  Tile(Area* area, const IVec2& pos, TileType type);
  virtual ~Tile();

  Area* getArea() const;
  const IVec2& getCoordinates() const;

private:
  IVec2 _pos;
  Area* _area;
};

#endif
