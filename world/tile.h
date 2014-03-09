#ifndef TILE_H
#define TILE_H

class Tile {
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
