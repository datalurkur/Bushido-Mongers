#ifndef TILE_BASE_H
#define TILE_BASE_H

#include "game/containerbase.h"

enum TileType {
  Wall,
  Ground
};

class TileBase: public ContainerBase {
public:
  TileBase(TileType type);
  virtual ~TileBase();

  void setType(TileType type);
  TileType getType() const;

private:
  TileType _type;
};

// For event packing
struct TileDatum {
  TileType type;
  set<BObjectID> contents;

  TileDatum();
  TileDatum(TileBase* tile);
};

#endif
