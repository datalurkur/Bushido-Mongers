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

extern ostream& operator<<(ostream& stream, TileDatum& data);
extern istream& operator>>(istream& stream, TileDatum& data);

#endif
