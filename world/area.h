#ifndef AREA_H
#define AREA_H

#include "world/tile.h"
#include "util/vector.h"

#include <string>
#include <vector>
#include <set>

using namespace std;

class Area {
  friend class WorldGenerator;
  friend class World;

public:
  Area(const string& name, const Vec2& pos, const Vec2& size);
  ~Area();

  const string& getName() const;

  const Vec2& getPos() const;
  const Vec2& getSize() const;

  Tile& getTile(int x, int y);
  Tile& getTile(const Vec2& pos);

protected:
  void addConnection(Area *o);
  const set<Area*>& getConnections() const;

private:
  string _name;
  Vec2 _pos, _size;
  set<Area*> _connections;

  vector<Tile> _tiles;
};

#endif
