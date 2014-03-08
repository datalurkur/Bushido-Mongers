#ifndef AREA_H
#define AREA_H

#include "world/tile.h"

#include <string>
#include <vector>
#include <set>

using namespace std;

class Area {
  friend class WorldGenerator;
  friend class World;

public:
  Area(const string& name, int xPos, int yPos, int xSize, int ySize);
  ~Area();

  const string& getName() const;

  int getXPos() const;
  int getYPos() const;
  int getXSize() const;
  int getYSize() const;

  Tile& getTile(int x, int y);

protected:
  void addConnection(Area *o);

private:
  string _name;
  int _xPos, _yPos, _xSize, _ySize;
  set<Area*> _connections;

  vector<Tile> _tiles;
};

#endif
