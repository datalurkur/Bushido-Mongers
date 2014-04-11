#ifndef AREA_BASE_H
#define AREA_BASE_H

#include "world/tilebase.h"
#include "util/vector.h"

#include <string>
#include <vector>
#include <set>

using namespace std;

class AreaBase {
public:
  AreaBase(const string& name, const IVec2& pos, const IVec2& size);
  virtual ~AreaBase();

  const string& getName() const;

  const IVec2& getPos() const;
  const IVec2& getSize() const;

  TileBase* getTile(const IVec2& pos);
  virtual void setTile(const IVec2& pos, TileBase* tile) = 0;

protected:
  void addConnection(const string& other);
  const set<string>& getConnections() const;

protected:
  IVec2 _size;
  string _name;
  IVec2 _pos;
  set<string> _connections;

  vector<TileBase*> _tiles;

  friend class WorldBase;
};

#endif
