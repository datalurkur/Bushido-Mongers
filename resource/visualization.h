#ifndef VISUALIZATION
#define VISUALIZATION

#include "resource/protobobject.h"
#include <map>
#include <list>
#include <set>
#include <string>

using namespace std;

class VisualizationMap {
public:
  VisualizationMap();

  bool load(const string& file);

  char get(const set<const ProtoBObject*>& contents);

private:
  size_t get(const ProtoBObject* proto, char& rep);

private:
  list<string> _order;
  map<string, char> _representation;
  map<const ProtoBObject*, char> _cache;
};

#endif
