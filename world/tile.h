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
  Tile(Area* area);
  Tile(Area* area, Type type);
  virtual ~Tile();

  void setType(Type type);
  Type getType() const;

  Area* getArea() const;

  const IVec2* getCoordinates() const;

protected:
  friend class Area;
  void setCoordinates(const IVec2& pos);

private:
  Area* _area;
  Type _type;
  IVec2 _pos;
};

#endif
