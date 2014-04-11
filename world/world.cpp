#include "world/world.h"
#include "util/filesystem.h"
#include "util/log.h"

#include <sstream>

World::World() {}

Area* World::getRandomArea() const {
  auto itr = _areas.begin();
  std::advance(itr, rand() % _areas.size());
  return (Area*)*itr;
}

void World::generateGraphVizFile(const string& filename) {
  ostringstream stream;
  stream << "strict graph WorldMap {\n\tnode [shape=point];\n";
  for(auto area : _areas) {
    stream << "\tnode [pos=\"" << area->getPos().x << "," << area->getPos().y << "!\"] \"" << area->getName() << "\";\n";
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
