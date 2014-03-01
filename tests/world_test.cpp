#include "world/generator.h"
#include "util/log.h"

int main() {
  Log::Setup();
  World* world = WorldGenerator::CloudGenerate(512, 0.2);
  if(world) {
    delete world;
  }
  Log::Teardown();
}
