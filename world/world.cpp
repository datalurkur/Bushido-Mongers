#include "world/world.h"
#include "util/filesystem.h"
#include "util/log.h"

#include <sstream>

World::World() {
}

World::~World() {
  for(auto area : _areas) {
    delete area;
  }
}

void World::generateGraphVizFile(const string& filename) {
  stringstream stream;
  stream << "strict graph WorldMap {\n\tnode [shape=point];\n";
  for(auto area : _areas) {
    stream << "\tnode [pos=\"" << area->getXPos() << "," << area->getYPos() << "!\"] \"" << area->getName() << "\";\n";
  }
  for(auto connectionSet : _connections) {
    for(auto connection : connectionSet.second) {
      stream << "\t\"" << connectionSet.first->getName() << "\" -- \"" << connection->getName() << "\";\n";
    }
  }
  stream << "}";
  string streamData = stream.str();
  FileSystem::SaveFileData(filename, streamData.c_str(), streamData.size());
  Info("GraphViz graph written to " << filename << "\nInvoke dot like so to produce an image:\ndot -Kneato -n -Tpng -o " << filename << ".png " << filename);
}

void World::addArea(Area* area) {
  _areas.push_back(area);
}

void World::addConnection(Area* a, Area* b) {
  auto aConnects = _connections.find(a),
       bConnects = _connections.find(b);
  if(aConnects == _connections.end()) {
    _connections.insert(make_pair(a, set<Area*> { b }));
  } else {
    _connections[a].insert(b);
  }
  if(bConnects == _connections.end()) {
    _connections.insert(make_pair(b, set<Area*> { a }));
  } else {
    _connections[b].insert(a);
  }
  a->addConnection(b);
  b->addConnection(a);
}
