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
  Tile();
  Tile(Type type);
  virtual ~Tile();

  void setType(Type type);
  Type getType() const;

  void setArea(Area* area);
  Area* getArea() const;

  const IVec2* getCoordinates() const;

protected:
  friend class Area;
  void setCoordinates(const IVec2& pos);

private:
  Type _type;
  Area* _area;
  IVec2 _pos;
};

#endif
