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

void cleanup(int signal) {
#if ENABLE_CURSES == 1
  CurseMe::Teardown();
#endif
  Log::Teardown();

  if(m_area != 0) {
    delete m_area;
    m_area = 0;
  }

  exit(signal);
}

void setup() {
  Log::Setup("stdout");
#if ENABLE_CURSES == 1
  CurseMe::Setup();
  init_pair(1, COLOR_WHITE, COLOR_YELLOW);
  init_pair(2, COLOR_GREEN, COLOR_BLACK);
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
  RenderSource groupData(area_size, area_size);

  groupData.setData('.', A_NORMAL);
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
      groupData.setData((int)member.x, (int)member.y, rep, A_NORMAL);
    }
  }

  RenderSource areaData(area_size, area_size);
  for(int j = 0; j < areaSize.y; j++) {
    for(int i = 0; i < areaSize.x; i++) {
      switch(m_area->getTile(IVec2(i, j))->getType()) {
      case TileType::Wall:
        areaData.setData(i, j, 'X', COLOR_PAIR(1));
        break;
      case TileType::Ground:
        areaData.setData(i, j, '.', A_DIM | COLOR_PAIR(2));
        break;
      default:
        areaData.setData(i, j, '?', A_NORMAL);
        break;
      }
    }
  }

  wrefresh(stdscr);
  RenderTarget renderTarget(stdscr, &areaData);
  renderTarget.render();

  int ch;
  while((ch = getch()) != KEY_F(1)) {
    switch(ch) {
    case KEY_LEFT:
      renderTarget.nudgeOffset(IVec2(-1, 0));
      renderTarget.render();
      break;
    case KEY_RIGHT:
      renderTarget.nudgeOffset(IVec2(1, 0));
      renderTarget.render();
      break;
    case KEY_UP:
      renderTarget.nudgeOffset(IVec2(0, 1));
      renderTarget.render();
      break;
    case KEY_DOWN:
      renderTarget.nudgeOffset(IVec2(0, -1));
      renderTarget.render();
      break;
    case 'a':
      renderTarget.setRenderSource(&groupData);
      renderTarget.render();
      break;
    case 's':
      renderTarget.setRenderSource(&areaData);
      renderTarget.render();
      break;
    }
  }
#endif

  cleanup(0);
}
