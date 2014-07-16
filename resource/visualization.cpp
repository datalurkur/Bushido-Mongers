#include "resource/visualization.h"
#include "util/filesystem.h"
#include "util/stringhelper.h"
#include "util/structure.h"

VisualizationMap::VisualizationMap() { }

bool VisualizationMap::load(const string& file) {
  void* data;
  unsigned int dataSize;
  dataSize = FileSystem::GetFileData(file, &data);
  if(dataSize == 0) {
    Error("Failed to read data from " << file);
    return false;
  }

  string stringData((char*)data, dataSize);
  free(data);

  list<string> tokens;
  TokenizeString(stringData, "\n", tokens);
  for(auto token : tokens) {
    string keyword;
    char ch;

    istringstream str(token);
    str >> keyword >> ch;

    Debug("Object " << keyword << " will be displayed as '" << ch << "'");

    _order.push_back(keyword);
    _representation.insert(make_pair(keyword, ch));
  }

  return true;
}

char VisualizationMap::get(const set<const ProtoBObject*>& contents) {
  const ProtoBObject* obj = 0;
  size_t priority = 0;
  char rep;
  for(auto c : contents) {
    size_t p = get(c, rep);
    if(p > priority) {
      obj = c;
    }
  }
  if(obj == 0) {
    return '?';
  }
  return rep;
}

size_t VisualizationMap::get(const ProtoBObject* proto, char& rep) {
  size_t index;
  list<string>::iterator itr;
  for(itr = _order.begin(), index = 1; itr != _order.end(); itr++, index++) {
    if(*itr == proto->name || contains(proto->keywords, *itr)) {
      rep = _representation[*itr];
      _cache[proto] = rep;
      break;
    }
  }
  //Debug("Prototype " << proto->name << " is ranked " << index << " with representation " << rep);
  return index;
}
