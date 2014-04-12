#ifndef CLIENT_AREA_H
#define CLIENT_AREA_H

#include "world/areabase.h"
#include "world/clienttile.h"

class ClientArea: public AreaBase {
public:
  ClientArea(const string& name, const IVec2& pos, const IVec2& size);
  ~ClientArea();

  void shroudTile(const IVec2& pos);
  void revealTile(const IVec2& pos);
  
  bool isTileShrouded(const IVec2& pos);
  
  void setTile(const IVec2& pos, TileBase* tile);

private:
  vector<bool> _shrouded;
};

#endif
