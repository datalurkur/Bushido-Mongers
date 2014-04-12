#include "world/clienttile.h"

ClientTile::ClientTile(TileType type, set<BObjectID>& contents, time_t changed): TileBase(type) {
  for(auto c : contents) {
    Debug("Adding " << c << " to client tile contents");
  }
  //_contents = contents;
  for(auto c : contents) {
    _contents.insert(c);
  }
  setLastChanged(changed);
}
