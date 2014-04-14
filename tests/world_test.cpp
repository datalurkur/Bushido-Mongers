#include "curseme/renderer.h"
#include "world/generator.h"
#include "util/log.h"
#include "util/vector.h"

#include <cstring>
#include <signal.h>
#include <unistd.h>
#include <sstream>

#define ENABLE_CURSES 1

using namespace std;

Area* m_area = 0;
char* groupData = 0;

void cleanup(int signal) {
#if ENABLE_CURSES == 1
  CurseMeTeardown();
#endif
  Log::Teardown();

  if(m_area != 0) {
    delete m_area;
    m_area = 0;
  }
  if(groupData != 0) {
    free(groupData);
    groupData = 0;
  }

  exit(signal);
}

void setup() {
  Log::Setup("stdout");
#if ENABLE_CURSES == 1
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
  int area_size = 128;
  m_area = new Area("Test Area", IVec2(10, 20), IVec2(area_size, area_size));
  const IVec2& areaSize = m_area->getSize();
  WorldGenerator::GenerateCave(m_area, 0.5, 1.0);

  map<int, set<IVec2>> grouped;
  WorldGenerator::ParseAreas(m_area, grouped);

#if ENABLE_CURSES == 1
  // Set up our renderer to fill the whole screen
  int maxX, maxY;
  getmaxyx(stdscr, maxY, maxX);
  int maxXOffset = max((int)areaSize.x - maxX, 0),
      maxYOffset = max((int)areaSize.y - maxY, 0);
  AsciiRenderer renderer(0, 0, maxX, maxY);

  groupData = (char*)malloc(areaSize.x * areaSize.y * sizeof(char));
  memset(groupData, '.', areaSize.x * areaSize.y);
  int groupCounter = -1;
  int maxGroupCounter = '~' - 'A';
  for(auto group : grouped) {
    groupCounter++;
    if(groupCounter > maxGroupCounter) { groupCounter -= maxGroupCounter; }
    char rep = 'A' + groupCounter;
    Debug("Using " << rep << " to represent group " << groupCounter);
    for(auto member : group.second) {
      if(member.x >= areaSize.x || member.y >= areaSize.y || member.x < 0 || member.y < 0) {
        Error("Member outside area bounds");
        continue;
      }
      groupData[(int)member.y * (int)areaSize.x + (int)member.x] = rep;
    }
  }

  ostringstream areaData;
  for(int j = 0; j < areaSize.y; j++) {
    for(int i = 0; i < areaSize.x; i++) {
      switch(m_area->getTile(IVec2(i, j))->getType()) {
      case TileType::Wall:
        areaData << "X";
        break;
      case TileType::Ground:
        areaData << ".";
        break;
      default:
        areaData << "?";
        break;
      }
    }
  }
  wrefresh(stdscr);
  renderer.setInputData(areaData.str().c_str(), areaSize.x, areaSize.y);
  //renderer.setInputData(groupData, areaSize.x, areaSize.y);
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
    case 'a':
      renderer.setInputData(groupData, areaSize.x, areaSize.y);
      renderer.render();
      break;
    case 's':
      renderer.setInputData(areaData.str().c_str(), areaSize.x, areaSize.y);
      renderer.render();
      break;
    }
  }
#endif

  cleanup(0);
}
