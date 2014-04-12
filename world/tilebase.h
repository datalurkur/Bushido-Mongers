#ifndef TILE_BASE_H
#define TILE_BASE_H

#include "game/bobjectcontainer.h"

enum TileType {
  Wall,
  Ground
};

class TileBase: public BObjectContainer {
public:
  TileBase(TileType type);
  virtual ~TileBase();

  void setType(TileType type);
  TileType getType() const;

private:
  TileType _type;
};

#endif
