#include "world/generator.h"
#include "util/log.h"

int main() {
  Log::Setup();
  World* world = WorldGenerator::CloudGenerate(1024, 0.5, 0.5, WorldGenerator::ConnectionMethod::MaxDistance);
  if(world) {
    world->generateGraphVizFile("graphviz_test.txt");
    delete world;
  }
  Log::Teardown();
}
