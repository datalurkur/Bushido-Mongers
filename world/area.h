#ifndef AREA_H
#define AREA_H

#include "world/areabase.h"
#include "world/tile.h"

class Area: public AreaBase {
  friend class WorldGenerator;

public:
  Area(const string& name, const IVec2& pos, const IVec2& size);

  Tile* getRandomEmptyTile();
  void setTile(const IVec2& pos, TileBase* tile);
};

#endif
