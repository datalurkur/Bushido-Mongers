#include "world/generator.h"
#include "util/log.h"

int main() {
  Log::Setup();
  World* world = WorldGenerator::CloudGenerate(1024, 0.5);
  if(world) {
    delete world;
  }
  Log::Teardown();
}
