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
  int maxXOffset = max(area->getXSize() - maxX, 0),
      maxYOffset = max(area->getYSize() - maxY, 0);
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
  wrefresh(stdscr);
  renderer.setInputData(areaData.str().c_str(), area->getXSize(), area->getYSize());
  renderer.render();

  int ch;
  while((ch = getch()) != KEY_F(1)) {
    int x = renderer.getInputX(),
        y = renderer.getInputY();

    switch(ch) {
    case KEY_LEFT:
      renderer.setInputX(max(0, x-1));
      renderer.render();
      break;
    case KEY_RIGHT:
      renderer.setInputX(min(maxXOffset, x+1));
      renderer.render();
      break;
    case KEY_UP:
      renderer.setInputY(max(0, y-1));
      renderer.render();
      break;
    case KEY_DOWN:
      renderer.setInputY(min(maxYOffset, y+1));
      renderer.render();
      break;
    }
  }

  cleanup(0);
}
