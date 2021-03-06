#include "curseme/window.h"
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
  World* world = WorldGenerator::GenerateWorld(100, 0.5, 0.5, WorldGenerator::ConnectionMethod::MaxDistance);
  if(world) {
    world->generateGraphVizFile("graphviz_test.txt");
    delete world;
  }
*/

  // Area generation test
  int area_size = 128;
  m_area = new Area("Test Area", IVec2(10, 20), IVec2(area_size, area_size));
  const IVec2& areaSize = m_area->getSize();

  AreaDescriptor desc("cave");
  desc.isOutdoors = false;
  desc.objectDensity = 0.2f;
  desc.peripheralObjects.insert("rock");
  // ============  END HACK  =============

  WorldGenerator::GenerateArea(m_area, desc, 0);

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
      case TileType::Wall: {
        short bits = 0;
        for(int m = -1; m <= 1; m++) {
          for(int n = -1; n <= 1; n++) {
            if(m == n && m == 0) { continue; }
            int x = i + m,
                y = j + n;
            int bit = MARCHING_SQUARES_BIT(m, n);
            if(x < 0 || x >= areaSize.x || y < 0 || y >= areaSize.y) {
              bits |= bit;
            } else {
              TileType t = m_area->getTile(IVec2(x, y))->getType();
              if(t == TileType::Wall) { bits |= bit; } 
            }
          }
        }
        areaData.setData(i, j, getMarchingSquaresRepresentation(bits), A_NORMAL);
      } break;
      case TileType::Ground:
        areaData.setData(i, j, '.', A_NORMAL);
        break;
      default:
        areaData.setData(i, j, '?', A_NORMAL);
        break;
      }
    }
  }

  Window mainWin(Window::Alignment::CENTER, 1.0f, 1.0f, 0, 0, 0, 0, 0);
  RenderTarget renderTarget(&mainWin, &areaData);
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
