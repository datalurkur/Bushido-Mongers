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
  Area(const string& name, const IVec2& pos, const IVec2& size);
  virtual ~Area();

  const string& getName() const;

  const IVec2& getPos() const;
  const IVec2& getSize() const;

  Tile* getTile(int x, int y);
  Tile* getTile(const IVec2& pos);
  Tile* getRandomEmptyTile();
  void setTile(int x, int y, Tile* tile);
  void setTile(const IVec2& pos, Tile* tile);

protected:
  void addConnection(Area *o);
  const set<Area*>& getConnections() const;

protected:
  IVec2 _size;

private:
  string _name;
  IVec2 _pos;
  set<Area*> _connections;

  vector<Tile*> _tiles;
};

class ClientArea: public Area {
public:
  ClientArea(const string& name, const IVec2& pos, const IVec2& size);
  ~ClientArea();

  void shroudTile(const IVec2& pos);
  void revealTile(const IVec2& pos);
  bool isTileShrouded(const IVec2& pos);

private:
  vector<bool> _shrouded;
};

#endif
