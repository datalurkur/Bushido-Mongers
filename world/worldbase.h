#ifndef WORLDBASE_H
#define WORLDBASE_H

#include "world/areabase.h"

#include <list>
#include <map>
#include <set>
#include <string>

using namespace std;

class WorldBase {
public:
  WorldBase();
  virtual ~WorldBase();

  AreaBase* getArea(const string& name) const;

protected:
  void addArea(AreaBase* area);
  bool hasArea(const string& name);
  void addConnection(AreaBase* a, AreaBase* b);

protected:
  list<AreaBase*> _areas;
  map<AreaBase*, set<AreaBase*> > _connections;
  map<string, AreaBase*> _namedAreas;
};

#endif
