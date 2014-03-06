#ifndef AREA_H
#define AREA_H

#include <string>
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

protected:
  void addConnection(Area *o);

private:
  string _name;
  int _xPos, _yPos, _xSize, _ySize;
  set<Area*> _connections;
};

#endif
