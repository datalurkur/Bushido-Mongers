#include "world/generator.h"
#include "util/log.h"

int main() {
  Log::Setup();
  World* world = WorldGenerator::CloudGenerate(1024, 1.0);
  if(world) {
    world->generateGraphVizFile("graphviz_test.txt");
    delete world;
  }
  Log::Teardown();
}
