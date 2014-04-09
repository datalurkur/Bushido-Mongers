#ifndef TILE_H
#define TILE_H

#include "game/bobjectcontainer.h"

class Tile: public BObjectContainer {
public:
  enum Type {
    Wall,
    Ground
  };

public:
  Tile(Area* area, const IVec2& pos, Type type);
  virtual ~Tile();

  void setType(Type type);
  Type getType() const;

  Area* getArea() const;
  const IVec2& getCoordinates() const;

private:
  Area* _area;
  IVec2 _pos;
  Type _type;
};

#endif
