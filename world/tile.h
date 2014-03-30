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
  ~Tile();

  void setType(Type type);
  Type getType() const;

private:
  Type _type;
};

#endif
