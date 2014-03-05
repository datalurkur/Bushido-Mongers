#ifndef AREA_H
#define AREA_H

#include <set>

using namespace std;

class Area {
  friend class WorldGenerator;
  friend class World;

public:
  Area(int xSize, int ySize);
  ~Area();

protected:
  void addConnection(Area *o);

private:
  int _xSize, _ySize;
  set<Area*> _connections;
};

#endif
