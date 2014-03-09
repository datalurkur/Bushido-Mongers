#include "curseme/renderer.h"
#include "world/generator.h"
#include "util/log.h"

#include <signal.h>
#include <unistd.h>
#include <sstream>

#define ENABLE_CURSES 1

using namespace std;

void cleanup(int signal) {
#ifdef ENABLE_CURSES
  CurseMeTeardown();
#endif
  Log::Teardown();

  exit(signal);
}

void setup() {
  Log::Setup();
#ifdef ENABLE_CURSES
  CurseMeSetup();
#endif
  signal(SIGINT, cleanup);
}

int main() {
  setup();
/*
  // Whole world generation test
  World* world = WorldGenerator::GenerateWorld(1024, 0.5, 0.5, WorldGenerator::ConnectionMethod::MaxDistance);
  if(world) {
    world->generateGraphVizFile("graphviz_test.txt");
    delete world;
  }
*/

  // Area generation test
  Area* area = new Area("Test Area", 10, 20, 256, 256);
  WorldGenerator::GenerateCave(area, 0.5, 0.5);

  // Set up our renderer to fill the whole screen
  int maxX, maxY;
  getmaxyx(stdscr, maxY, maxX);
  AsciiRenderer renderer(0, 0, maxX, maxY);

  ostringstream areaData;
  for(int j = 0; j < area->getYSize(); j++) {
    for(int i = 0; i < area->getXSize(); i++) {
      switch(area->getTile(i, j).getType()) {
      case Tile::Type::Wall:
        areaData << "X";
        break;
      case Tile::Type::Ground:
        areaData << ".";
        break;
      default:
        areaData << "?";
        break;
      }
    }
  }
  delete area;
  renderer.setInputData(areaData.str().c_str(), area->getXSize(), area->getYSize());
  renderer.render();
  while(true) {
    sleep(1);
  }

  cleanup(0);
}
